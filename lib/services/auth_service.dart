import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/app_features.dart';
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

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);

    if (!AppConfig.hasApi) {
      // Dev / offline mode — OTP is accepted without a real SMS
      await Future.delayed(const Duration(milliseconds: 600));
      state = state.copyWith(isLoading: false);
      return true;
    }

    try {
      final res = await http
          .post(
            AppConfig.authUri('/api/auth/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      state = state.copyWith(
          isLoading: false, error: body['error'] as String? ?? 'server_error');
      return false;
    } catch (e) {
      debugPrint('sendOtp error: $e');
      state = state.copyWith(isLoading: false, error: 'connection_error');
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);

    if (!AppConfig.hasApi) {
      // Dev mode — any code works
      await Future.delayed(const Duration(milliseconds: 600));
      if (code.length >= 4) {
        final user = User(
          id: 'dev_${DateTime.now().millisecondsSinceEpoch}',
          phone: phone,
          token: 'dev_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        await _storage.saveAuth(user.toJson());
        state = AuthState(user: user);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'invalid_code');
      return false;
    }

    try {
      final res = await http
          .post(
            AppConfig.authUri('/api/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone, 'code': code}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['ok'] == true) {
        final serverUser = body['user'] as Map<String, dynamic>;
        final user = User(
          id: serverUser['id'].toString(),
          phone: serverUser['phone'] as String,
          token: body['token'] as String,
        );
        await _storage.saveAuth(user.toJson());
        state = AuthState(user: user);
        return true;
      }

      state = state.copyWith(
          isLoading: false,
          error: body['error'] as String? ?? 'invalid_code');
      return false;
    } catch (e) {
      debugPrint('verifyOtp error: $e');
      state = state.copyWith(isLoading: false, error: 'connection_error');
      return false;
    }
  }

  Future<void> setPro(int months) async {
    if (state.user == null) return;
    final newExpiry = DateTime.now().add(Duration(days: months * 30));
    final updatedUser = state.user!.copyWith(expirePro: newExpiry);
    await _storage.saveAuth(updatedUser.toJson());
    state = AuthState(user: updatedUser);
  }

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
