# Kontrak API Auth (JWT)

Status: berdasarkan jawaban Pandi. **Konfirmasi ulang dengan response asli backend.**

Base URL: `http://<host>:8000/api`
Semua request: header `Accept: application/json`.
Endpoint selain register dan login: header `Authorization: Bearer <access_token>`.

Paket JWT: `php-open-source-saver/jwt-auth`
- Access token berlaku 60 menit (`JWT_TTL=60`)
- Masa refresh 2 minggu (`JWT_REFRESH_TTL=20160` menit)
- Tidak ada refresh token terpisah: token lama dikirim ke `/auth/refresh`, dibalas token baru.

## POST /auth/register
Request:
```json
{ "name": "Bayu", "email": "bayu@mail.com", "password": "rahasia123", "password_confirmation": "rahasia123" }
```
Response 201: sama seperti login.
Response 422:
```json
{ "message": "...", "errors": { "email": ["..."] } }
```

## POST /auth/login
Request:
```json
{ "email": "bayu@mail.com", "password": "rahasia123" }
```
Response 200 (tanpa pembungkus `data`):
```json
{
  "access_token": "eyJ0eXAiOiJKV1Qi...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": { "id": 1, "name": "Pandi", "email": "pandi@example.com" }
}
```
`expires_in` dalam detik.
Response 401 atau 422: `{ "message": "Email atau kata sandi salah" }`

## POST /auth/refresh
Header: `Authorization: Bearer <token lama>` (boleh sudah kedaluwarsa selama masih dalam masa refresh)
Response 200: bentuk sama seperti login (token baru).
Response 401: token tidak bisa diperbarui, klien kembali ke login.

## POST /auth/logout
Memasukkan token ke blacklist. Setelah itu token ditolak dengan 401.
Klien tetap menghapus token dari secure storage.

## GET /me
Response 200: data user (bentuk final dikonfirmasi dengan Pandi).
Response 401: token tidak valid atau kedaluwarsa, klien coba `/auth/refresh` sekali.

## Aturan di klien (Flutter)
- 401 pada endpoint selain auth: coba `/auth/refresh` sekali, ulangi request. Kalau gagal, hapus token dan ke login.
- 401/422 pada login: tampilkan `message`, jangan coba refresh.
- 422 validasi: tampilkan `errors` per kolom.

## Yang masih perlu dikonfirmasi ke Pandi
1. Apakah response asli persis seperti contoh di atas (field `access_token`, tanpa `data`)?
2. Bentuk response `GET /me`.
3. Alamat dan port backend untuk dev.