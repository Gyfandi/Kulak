/// DTO (Data Transfer Object) untuk data pengguna dari API.
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  /// JSON -> objek Dart. Nama key mengikuti kontrak API (snake_case).
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  /// Objek Dart -> JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
      };
}