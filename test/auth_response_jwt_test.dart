import 'package:flutter_test/flutter_test.dart';
import 'package:kulak/data/models/auth_response.dart';

void main() {
  test('AuthResponse membaca bentuk JWT (access_token, tanpa "data")', () {
    final res = AuthResponse.fromJson({
      'access_token': 'eyJ0eXAi...',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {'id': 1, 'name': 'Pandi', 'email': 'pandi@example.com'},
    });

    expect(res.token, 'eyJ0eXAi...');
    expect(res.user.name, 'Pandi');
    expect(res.user.email, 'pandi@example.com');
  });
}