import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/location_service.dart';
import '../services/telephony_service.dart';

class DetailDemoPage extends StatefulWidget {
  final String itemId;
  const DetailDemoPage({super.key, required this.itemId});

  @override
  State<DetailDemoPage> createState() => _DetailDemoPageState();
}

class _DetailDemoPageState extends State<DetailDemoPage> {
  // Data dummy barang (nanti diganti data dari API)
  final String _nama = 'Sepeda Bekas';
  final String _nomorPenjual = '6281234567890';
  final double _latPenjual = -7.9666;
  final double _lngPenjual = 112.6326;

  String _jarak = 'Menghitung jarak...';
  String? _fotoPath;

  @override
  void initState() {
    super.initState();
    _hitungJarak();
  }

  Future<void> _hitungJarak() async {
    final pos = await LocationService.getPosition();
    if (!mounted) return;
    setState(() {
      if (pos == null) {
        _jarak = 'Izin lokasi ditolak';
      } else {
        final km = LocationService.distanceKm(
            pos.latitude, pos.longitude, _latPenjual, _lngPenjual);
        _jarak = '${km.toStringAsFixed(1)} km dari kamu';
      }
    });
  }

  Future<void> _ambilFoto() async {
    final foto = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 70);
    if (foto != null) setState(() => _fotoPath = foto.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail Barang #${widget.itemId}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_nama, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_jarak),
            const SizedBox(height: 16),
            if (_fotoPath != null) Text('Foto tersimpan: $_fotoPath'),
            ElevatedButton.icon(
              onPressed: _ambilFoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto Barang'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () =>
                  TelephonyService.hubungiPenjual(_nomorPenjual, _nama),
              icon: const Icon(Icons.chat),
              label: const Text('Hubungi Penjual'),
            ),
          ],
        ),
      ),
    );
  }
}
