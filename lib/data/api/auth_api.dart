import 'package:dio/dio.dart';

import '../models/auth_response.dart';
import '../models/user.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Fungsi login/registrasi/logout/profil.
///
/// [useMock] = true -> pakai data tiruan (backend belum siap).
/// Setelah backend A jadi, ubah menjadi false. UI tidak perlu diubah.
class AuthApi {
  final ApiClient client;
  final TokenStorage storage;
  final bool useMock;

  AuthApi({
    required this.client,
    required this.storage,
    this.useMock = true,
  });

  Future<AuthResponse> login(String email, String password) async {
    final result = useMock
        ? await _mockLogin(email, password)
        : await _post('/auth/login', {'email': email, 'password': password});
    await storage.save(result.token);
    return result;
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final result = useMock
        ? await _mockRegister(name, email, password)
        : await _post('/auth/register', {
            'name': name,
            'email': email,
            'password': password,
            'password_confirmation': passwordConfirmation,
          });
    await storage.save(result.token);
    return result;
  }

  Future<void> logout() async {
    try {
      if (!useMock) await client.dio.post('/auth/logout');
    } on DioException {
      // Abaikan: apa pun hasilnya, token lokal tetap dihapus.
    } finally {
      await storage.clear();
    }
  }

  Future<User> getMe() async {
    if (useMock) {
      return const User(id: 1, name: 'Pengguna Mock', email: 'mock@kulak.test');
    }
    try {
      final res = await client.dio.get('/me');
      final body = res.data as Map<String, dynamic>;
      return User.fromJson((body['data'] ?? body) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---- Panggilan sungguhan ----
  Future<AuthResponse> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await client.dio.post(path, data: body);
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---- Data tiruan ----
  Future<AuthResponse> _mockLogin(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (password.length < 6) {
      throw const ApiException(
        message: 'Email atau password salah.',
        statusCode: 401,
      );
    }
    return AuthResponse(
      user: User(id: 1, name: 'Pengguna Mock', email: email),
      token: 'mock-token-123',
    );
  }

  Future<AuthResponse> _mockRegister(
    String name,
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (email.startsWith('taken@')) {
      throw const ApiException(
        message: 'Data tidak valid.',
        statusCode: 422,
        fieldErrors: {
          'email': ['Email sudah terdaftar.'],
        },
      );
    }
    return AuthResponse(
      user: User(id: 2, name: name, email: email),
      token: 'mock-token-456',
    );
  }
}