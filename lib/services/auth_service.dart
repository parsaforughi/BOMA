import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Local OTP flow for v1 — real SMS API can be wired later.
  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 800));

    if (code.length == 4) {
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        phone: phone,
        token: 'local_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      await _storage.saveAuth(user.toJson());
      state = AuthState(user: user);
      return true;
    }

    state = state.copyWith(isLoading: false, error: 'invalid_code');
    return false;
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
