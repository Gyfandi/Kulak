import 'package:url_launcher/url_launcher.dart';

/// Mengubah nomor telepon Indonesia ke format internasional tanpa tanda "+",
/// contoh: "0812-3456-7890" -> "6281234567890". Mengembalikan null jika tidak valid.
String? normalizeIndonesianPhone(String? raw) {
  if (raw == null) return null;
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;

  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('62')) {
    // sudah format internasional
  } else if (digits.startsWith('0')) {
    digits = '62${digits.substring(1)}';
  } else if (digits.startsWith('8')) {
    digits = '62$digits';
  }

  if (digits.length < 10 || digits.length > 15) return null;
  return digits;
}

/// Tautan untuk memanggil nomor (dial). [digits] harus hasil [normalizeIndonesianPhone].
Uri telUri(String digits) => Uri(scheme: 'tel', path: '+$digits');

/// Tautan chat WhatsApp. [digits] harus hasil [normalizeIndonesianPhone].
Uri whatsappUri(String digits, String message) =>
    Uri.https('wa.me', '/$digits', {'text': message});

/// Membuka [uri] di aplikasi luar. Mengembalikan false jika gagal
/// (misalnya di desktop/web yang tidak punya aplikasi telepon).
Future<bool> openExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}