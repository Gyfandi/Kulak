import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// HTTP client utama. Semua fitur (katalog, favorit, dst.) memakai instance
/// ini, jadi token otomatis ikut terkirim dan otomatis diperbarui (refresh).
class ApiClient {
  /// Ganti saat build: flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000/api
  /// 10.0.2.2 = alamat laptop dari dalam emulator Android.
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  /// Dio utama (dengan interceptor).
  final Dio dio;

  /// Dio khusus untuk memanggil /auth/refresh. Sengaja TANPA interceptor
  /// supaya tidak terjadi pengulangan tak terbatas saat refresh itu sendiri gagal.
  final Dio _refreshDio;

  final TokenStorage tokenStorage;

  /// Dipanggil saat token tidak bisa diperbarui lagi (refresh gagal).
  /// Isi dengan fungsi yang mengarahkan pengguna ke layar login.
  final void Function()? onUnauthorized;

  /// Kalau beberapa request kena 401 bersamaan, semuanya menunggu
  /// satu proses refresh yang sama.
  Future<String?>? _refreshing;

  static BaseOptions _options(String? baseUrl) => BaseOptions(
        baseUrl: baseUrl ?? defaultBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
      );

  ApiClient({
    required this.tokenStorage,
    this.onUnauthorized,
    String? baseUrl,
  })  : dio = Dio(_options(baseUrl)),
        _refreshDio = Dio(_options(baseUrl)) {
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
        // Saat error 401: coba refresh sekali, lalu ulangi request.
        onError: (error, handler) async {
          final request = error.requestOptions;
          final is401 = error.response?.statusCode == 401;

          // Bukan 401, atau endpoint auth (login salah, dst.): teruskan apa adanya.
          if (!is401 || _isAuthPath(request.path)) {
            return handler.next(error);
          }

          // Sudah pernah diulang dan masih 401: menyerah.
          if (request.extra['retried'] == true) {
            await _giveUp();
            return handler.next(error);
          }

          final newToken = await _refreshToken();
          if (newToken == null) {
            await _giveUp();
            return handler.next(error);
          }

          try {
            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer $newToken';
            final response = await dio.fetch(request);
            handler.resolve(response);
          } on DioException catch (e) {
            handler.next(e);
          }
        },
      ),
    );
  }

  bool _isAuthPath(String path) =>
      path.endsWith('/auth/login') ||
      path.endsWith('/auth/register') ||
      path.endsWith('/auth/refresh') ||
      path.endsWith('/auth/logout');

  Future<void> _giveUp() async {
    await tokenStorage.clear();
    onUnauthorized?.call();
  }

  Future<String?> _refreshToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  /// POST /auth/refresh dengan token lama di header Bearer.
  /// Balasan: bentuk yang sama seperti login ({access_token, ...}).
  Future<String?> _doRefresh() async {
    final oldToken = await tokenStorage.read();
    if (oldToken == null) return null;

    try {
      final res = await _refreshDio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $oldToken'}),
      );
      final body = res.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;
      final newToken = (data['access_token'] ?? data['token']) as String?;
      if (newToken == null) return null;

      await tokenStorage.save(newToken);
      return newToken;
    } on DioException {
      return null;
    }
  }
}