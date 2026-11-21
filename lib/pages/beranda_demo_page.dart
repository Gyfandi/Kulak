import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import 'detail_demo_page.dart';

class BerandaDemoPage extends StatefulWidget {
  const BerandaDemoPage({super.key});

  @override
  State<BerandaDemoPage> createState() => _BerandaDemoPageState();
}

class _BerandaDemoPageState extends State<BerandaDemoPage>
    with WidgetsBindingObserver {
  StreamSubscription? _accSub;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  final _judulC = TextEditingController();
  final _hargaC = TextEditingController();

  int _jumlahRefresh = 0;
  String _lokasi = 'Lokasi belum diambil';
  String _status = 'Lifecycle: resumed';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startShake();
    _loadDraft();
    _refreshLokasi();
  }

  // SENSOR: goyang untuk menyegarkan data barang sekitar
  void _startShake() {
    _accSub?.cancel();
    _accSub = userAccelerometerEventStream().listen((e) {
      final g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (g > 12 &&
          DateTime.now().difference(_lastShake) >
              const Duration(seconds: 2)) {
        _lastShake = DateTime.now();
        _jumlahRefresh++;
        _refreshLokasi();
      }
    });
  }

  // LBS: ambil lokasi terbaru
  Future<void> _refreshLokasi() async {
    final pos = await LocationService.getPosition();
    if (!mounted) return;
    setState(() {
      _lokasi = pos == null
          ? 'Izin lokasi ditolak'
          : 'Lat ${pos.latitude.toStringAsFixed(4)}, '
              'Lng ${pos.longitude.toStringAsFixed(4)} '
              '(refresh ke-$_jumlahRefresh)';
    });
  }

  // LIFECYCLE: simpan dan pulihkan draf iklan
  Future<void> _saveDraft() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('draft_judul', _judulC.text);
    await p.setString('draft_harga', _hargaC.text);
  }

  Future<void> _loadDraft() async {
    final p = await SharedPreferences.getInstance();
    _judulC.text = p.getString('draft_judul') ?? '';
    _hargaC.text = p.getString('draft_harga') ?? '';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() => _status = 'Lifecycle: ${state.name}');
    if (state == AppLifecycleState.paused) {
      _accSub?.cancel();
      _saveDraft();
    } else if (state == AppLifecycleState.resumed) {
      _startShake();
      _loadDraft();
      _refreshLokasi();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accSub?.cancel();
    _judulC.dispose();
    _hargaC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kulak - Beranda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_status),
          const SizedBox(height: 8),
          Text(_lokasi),
          const Text('Goyangkan HP untuk menyegarkan lokasi'),
          const Divider(height: 32),
          const Text('Draf Pasang Iklan (tersimpan otomatis saat app ditutup)'),
          TextField(
            controller: _judulC,
            decoration: const InputDecoration(labelText: 'Judul barang'),
          ),
          TextField(
            controller: _hargaC,
            decoration: const InputDecoration(labelText: 'Harga'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DetailDemoPage(itemId: '1')),
            ),
            child: const Text('Buka Detail Barang'),
          ),
        ],
      ),
    );
  }
}
