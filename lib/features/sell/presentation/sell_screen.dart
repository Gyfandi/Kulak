import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/location_service.dart';

/// Form pasang iklan: kamera (sensor), lokasi (LBS), draf tersimpan (lifecycle).
class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> with WidgetsBindingObserver {
  final _namaC = TextEditingController();
  final _hargaC = TextEditingController();
  Uint8List? _fotoBytes;
  String _lokasi = 'Lokasi belum diambil';
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDraft();
  }

  Future<void> _saveDraft() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('sell_nama', _namaC.text);
    await p.setString('sell_harga', _hargaC.text);
  }

  Future<void> _loadDraft() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _namaC.text = p.getString('sell_nama') ?? '';
      _hargaC.text = p.getString('sell_harga') ?? '';
    });
  }

  Future<void> _clearDraft() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('sell_nama');
    await p.remove('sell_harga');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _saveDraft();
    } else if (state == AppLifecycleState.resumed) {
      _loadDraft();
    }
  }

  Future<void> _ambilFoto() async {
    final foto = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 70);
    if (foto == null) return;
    final bytes = await foto.readAsBytes();
    if (!mounted) return;
    setState(() => _fotoBytes = bytes);
  }

  Future<void> _ambilLokasi() async {
    setState(() => _lokasi = 'Mengambil lokasi...');
    final pos = await LocationService.getPosition();
    if (!mounted) return;
    setState(() {
      if (pos == null) {
        _lokasi = 'Izin lokasi ditolak atau GPS mati';
      } else {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _lokasi = 'Lat ${pos.latitude.toStringAsFixed(5)}, '
            'Lng ${pos.longitude.toStringAsFixed(5)}';
      }
    });
  }

  Future<void> _simpan() async {
    if (_namaC.text.trim().isEmpty || _hargaC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan harga wajib diisi')),
      );
      return;
    }
    // TODO: kirim ke API (nama, harga, foto, _lat, _lng)
    await _clearDraft();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Iklan "${_namaC.text}" siap dikirim '
              '(lat: ${_lat ?? '-'}, lng: ${_lng ?? '-'})')),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _namaC.dispose();
    _hargaC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pasang Iklan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_fotoBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_fotoBytes!, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _ambilFoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Ambil Foto Barang'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _namaC,
            onChanged: (_) => _saveDraft(),
            decoration: const InputDecoration(
                labelText: 'Nama barang', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hargaC,
            onChanged: (_) => _saveDraft(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Harga (Rp)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Text(_lokasi),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _ambilLokasi,
            icon: const Icon(Icons.my_location),
            label: const Text('Ambil Lokasi Penjual'),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _simpan, child: const Text('Simpan Iklan')),
        ],
      ),
    );
  }
}
