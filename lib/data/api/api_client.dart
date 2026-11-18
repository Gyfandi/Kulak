import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// HTTP client utama. Semua fitur (katalog, favorit, dst.) memakai instance
/// ini, jadi token otomatis ikut terkirim.
class ApiClient {
  /// Ganti saat build: flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000/api
  /// 10.0.2.2 = alamat laptop dari dalam emulator Android.
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  final Dio dio;
  final TokenStorage tokenStorage;

  /// Dipanggil saat server membalas 401 (token tidak valid/kedaluwarsa).
  /// Isi dengan fungsi yang mengarahkan pengguna ke layar login.
  final void Function()? onUnauthorized;

  ApiClient({
    required this.tokenStorage,
    this.onUnauthorized,
    String? baseUrl,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? defaultBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        // Sebelum request dikirim: pasang header Authorization.
        onRequest: (options, handler) async {
          final token = await tokenStorage.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        // Saat error: kalau 401 (selain di login), hapus token + tendang ke login.
        onError: (error, handler) async {
          final is401 = error.response?.statusCode == 401;
          final isLogin = error.requestOptions.path.endsWith('/auth/login');
          if (is401 && !isLogin) {
            await tokenStorage.clear();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }
}