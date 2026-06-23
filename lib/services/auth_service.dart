import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_features.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'storage_service.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;
  bool get isPro => kAllFeaturesFreeForNow || (user?.isPro ?? false);

  AuthState copyWith(
      {User? user, bool? isLoading, String? error, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final StorageService _storage;

  AuthNotifier(this._storage) : super(const AuthState()) {
    _loadUser();
  }

  void _loadUser() {
    final data = _storage.getAuth();
    if (data != null) {
      try {
        final user = User.fromJson(data);
        if (user.token != null) {
          state = AuthState(user: user);
        }
      } catch (_) {}
    }
  }

  /// Sends OTP via backend API.
  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (!AppConfig.hasApi) {
        await Future.delayed(const Duration(milliseconds: 600));
        state = state.copyWith(isLoading: false);
        return true;
      }

      final response = await http.post(
        AppConfig.sendOtpUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      state = state.copyWith(isLoading: false);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'network_error');
      return false;
    }
  }

  /// Verifies OTP and logs in user.
  Future<bool> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (!AppConfig.hasApi) {
        await Future.delayed(const Duration(milliseconds: 700));
        if (code.length != 4) {
          state = state.copyWith(isLoading: false, error: 'invalid_code');
          return false;
        }
        final user = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          phone: phone,
          token: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        await _storage.saveAuth(user.toJson());
        state = AuthState(user: user);
        return true;
      }

      final response = await http.post(
        AppConfig.verifyOtpUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'code': code}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        state = state.copyWith(isLoading: false, error: 'invalid_code');
        return false;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final userJson = (payload['user'] as Map<String, dynamic>? ?? {});
      final token = payload['token']?.toString();

      final user = User.fromJson({...userJson, 'token': token});
      await _storage.saveAuth(user.toJson());
      state = AuthState(user: user);
      return true;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'network_error');
      return false;
    }
  }

  /// Set user as pro
  Future<void> setPro(int months) async {
    if (state.user == null) return;
    final newExpiry = DateTime.now().add(Duration(days: months * 30));
    final updatedUser = state.user!.copyWith(expirePro: newExpiry);
    await _storage.saveAuth(updatedUser.toJson());
    state = AuthState(user: updatedUser);
  }

  /// Logout
  Future<void> logout() async {
    await _storage.removeAuth();
    state = const AuthState();
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(storage);
});
