import 'package:flutter_test/flutter_test.dart';
import 'package:kulak/data/api/api_exception.dart';
import 'package:kulak/data/models/auth_response.dart';
import 'package:kulak/data/models/user.dart';
import 'package:dio/dio.dart';

void main() {
  group('User', () {
    test('fromJson membaca semua field', () {
      final user = User.fromJson({
        'id': 7,
        'name': 'Bayu',
        'email': 'bayu@mail.com',
        'phone': '0812',
        'avatar_url': null,
      });
      expect(user.id, 7);
      expect(user.name, 'Bayu');
      expect(user.phone, '0812');
      expect(user.avatarUrl, isNull);
    });

    test('toJson lalu fromJson menghasilkan data yang sama', () {
      const user = User(id: 1, name: 'A', email: 'a@mail.com');
      final again = User.fromJson(user.toJson());
      expect(again.email, user.email);
    });
  });

  group('AuthResponse', () {
    final json = {
      'message': 'ok',
      'data': {
        'user': {'id': 1, 'name': 'A', 'email': 'a@mail.com'},
        'token': 'abc123',
      },
    };

    test('membaca bentuk dibungkus "data"', () {
      final res = AuthResponse.fromJson(json);
      expect(res.token, 'abc123');
      expect(res.user.name, 'A');
    });

    test('membaca bentuk tanpa "data"', () {
      final res = AuthResponse.fromJson(json['data'] as Map<String, dynamic>);
      expect(res.token, 'abc123');
    });
  });

  group('ApiException', () {
    test('422 menghasilkan fieldErrors', () {
      final req = RequestOptions(path: '/auth/register');
      final err = DioException(
        requestOptions: req,
        response: Response(
          requestOptions: req,
          statusCode: 422,
          data: {
            'message': 'Data tidak valid.',
            'errors': {
              'email': ['Email sudah terdaftar.'],
            },
          },
        ),
      );
      final ex = ApiException.fromDio(err);
      expect(ex.statusCode, 422);
      expect(ex.fieldErrors['email'], ['Email sudah terdaftar.']);
    });
  });
}