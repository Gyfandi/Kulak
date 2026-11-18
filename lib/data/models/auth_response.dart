import 'user.dart';

/// Response login/registrasi: data user + token.
///
/// Asumsi bentuk JSON (sesuaikan dengan kontrak yang disepakati dengan A):
/// { "message": "...", "data": { "user": {...}, "token": "..." } }
class AuthResponse {
  final User user;
  final String token;

  const AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Dukung dua bentuk: dibungkus "data" atau langsung di root.
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    return AuthResponse(
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      token: (data['access_token'] ?? data['token']) as String,
    );
  }
}