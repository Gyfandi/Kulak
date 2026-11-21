import 'package:url_launcher/url_launcher.dart';

class TelephonyService {
  // nomor format internasional tanpa +, contoh: 6281234567890
  static Future<void> hubungiPenjual(String nomor, String namaBarang) async {
    final pesan = Uri.encodeComponent('Halo, $namaBarang masih tersedia?');
    final wa = Uri.parse('https://wa.me/$nomor?text=$pesan');
    final ok = await launchUrl(wa, mode: LaunchMode.externalApplication);
    if (!ok) {
      await launchUrl(Uri.parse('tel:+$nomor'));
    }
  }
}
