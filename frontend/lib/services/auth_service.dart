import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<AuthTokens> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = 'customer',
  }) async {
    final response = await _api.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'role': role,
    });
    final tokens = AuthTokens.fromJson(response.data);
    await _saveTokens(tokens);
    return tokens;
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final tokens = AuthTokens.fromJson(response.data);
    await _saveTokens(tokens);
    return tokens;
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }

  Future<User?> getCurrentUser() async {
    final userData = await _storage.read(key: AppConstants.userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    try {
      final response = await _api.get('/users/me');
      if (response.data['success'] == true) {
        return User.fromJson(response.data['data']);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveTokens(AuthTokens tokens) async {
    await _storage.write(
      key: AppConstants.accessTokenKey,
      value: tokens.accessToken,
    );
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: tokens.refreshToken,
    );
    await _storage.write(
      key: AppConstants.userKey,
      value: jsonEncode(tokens.user.toJson()),
    );
  }
}
