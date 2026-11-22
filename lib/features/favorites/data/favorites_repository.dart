import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../home/data/product.dart';

/// Daftar barang favorit, disimpan lokal di Hive supaya tetap ada setelah
/// aplikasi ditutup dan bisa dibuka saat offline.
///
/// Memakai [ChangeNotifier] agar tombol hati di detail dan layar Favorit
/// selalu sinkron.
class FavoritesRepository extends ChangeNotifier {
  FavoritesRepository({Future<Box<String>> Function()? openBox})
      : _openBox = openBox ?? _defaultOpenBox;

  final Future<Box<String>> Function() _openBox;
  Future<Box<String>>? _boxFuture;
  Future<void>? _loading;
  List<Product> _items = const [];

  /// Favorit terbaru di urutan paling atas.
  List<Product> get items => _items;

  bool isFavorite(int productId) => _items.any((p) => p.id == productId);

  static Future<Box<String>> _defaultOpenBox() async {
    await Hive.initFlutter();
    return Hive.openBox<String>('kulak_favorites');
  }

  Future<Box<String>> _box() async {
    try {
      return await (_boxFuture ??= _openBox());
    } catch (_) {
      _boxFuture = null; // izinkan percobaan ulang
      rethrow;
    }
  }

  /// Membaca favorit dari penyimpanan (hanya sekali; gagal -> bisa dicoba lagi).
  Future<void> ensureLoaded() async {
    final pending = _loading ??= _read();
    try {
      await pending;
    } catch (_) {
      if (identical(_loading, pending)) _loading = null;
      rethrow;
    }
  }

  Future<void> _read() async {
    final box = await _box();
    final entries = <({int savedAt, Product product})>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        entries.add((
          savedAt: (map['saved_at'] as num?)?.toInt() ?? 0,
          product: Product.fromJson(map['product'] as Map<String, dynamic>),
        ));
      } catch (_) {
        // Data rusak dilewati, tidak membuat seluruh daftar gagal.
      }
    }
    entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    _items = entries.map((e) => e.product).toList(growable: false);
    notifyListeners();
  }

  /// Menambah atau menghapus favorit. Mengembalikan true jika sekarang favorit.
  Future<bool> toggle(Product product) async {
    await ensureLoaded();
    final box = await _box();
    final key = product.id.toString();

    if (isFavorite(product.id)) {
      await box.delete(key);
      _items = _items.where((p) => p.id != product.id).toList(growable: false);
      notifyListeners();
      return false;
    }

    await box.put(
      key,
      jsonEncode({
        'saved_at': DateTime.now().millisecondsSinceEpoch,
        'product': product.toJson(),
      }),
    );
    _items = [product, ..._items];
    notifyListeners();
    return true;
  }
}