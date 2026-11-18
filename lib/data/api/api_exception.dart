import 'package:dio/dio.dart';

/// Error yang sudah "rapi" untuk ditampilkan di UI.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Error per kolom dari validasi (HTTP 422), mis. {"email": ["sudah dipakai"]}.
  final Map<String, List<String>> fieldErrors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  /// Ubah DioException (error mentah) menjadi ApiException.
  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;

    String message = 'Terjadi kesalahan. Coba lagi.';
    final fields = <String, List<String>>{};

    if (body is Map<String, dynamic>) {
      message = (body['message'] as String?) ?? message;
      final errors = body['errors'];
      if (errors is Map<String, dynamic>) {
        errors.forEach((key, value) {
          fields[key] = List<String>.from(value as List);
        });
      }
    } else if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      message = 'Tidak dapat terhubung ke server.';
    }

    return ApiException(
      message: message,
      statusCode: status,
      fieldErrors: fields,
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}