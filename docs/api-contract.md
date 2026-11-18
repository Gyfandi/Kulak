# Kontrak API Auth (DRAF, perlu disetujui A)

Base URL: `http://<host>:8000/api`
Semua request: header `Accept: application/json`.
Endpoint yang butuh login: header `Authorization: Bearer <token>`.

## POST /auth/register
Request:
```json
{ "name": "Bayu", "email": "bayu@mail.com", "password": "rahasia123", "password_confirmation": "rahasia123" }
```
Response 201:
```json
{ "message": "Registrasi berhasil", "data": { "user": { "id": 1, "name": "Bayu", "email": "bayu@mail.com", "phone": null, "avatar_url": null }, "token": "1|abcdef..." } }
```
Response 422 (validasi):
```json
{ "message": "Data tidak valid.", "errors": { "email": ["Email sudah terdaftar."] } }
```

## POST /auth/login
Request:
```json
{ "email": "bayu@mail.com", "password": "rahasia123" }
```
Response 200: sama seperti register.
Response 401: `{ "message": "Email atau password salah." }`

## POST /auth/logout  (butuh token)
Response 200: `{ "message": "Berhasil keluar" }`

## GET /me  (butuh token)
Response 200:
```json
{ "data": { "id": 1, "name": "Bayu", "email": "bayu@mail.com", "phone": null, "avatar_url": null } }
```
Response 401: token tidak valid atau kedaluwarsa.

## Pertanyaan untuk A
1. Sanctum atau JWT? Ada refresh token atau tidak?
2. Apakah bentuk response (`data.user`, `data.token`) sesuai?
3. Port dan alamat backend untuk dev?