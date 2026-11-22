import 'package:flutter/foundation.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.productId,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  /// Jika terisi, mengetuk notifikasi membuka detail barang ini.
  final int? productId;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        productId: productId,
        read: read ?? this.read,
      );
}

/// Daftar notifikasi dalam aplikasi.
///
/// TODO(Adi): sambungkan ke push notification (FCM) dengan memanggil [add]
/// saat pesan masuk. Saat ini isinya data contoh (mock).
class NotificationsRepository extends ChangeNotifier {
  NotificationsRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  List<AppNotification> _items = const [];
  bool _loaded = false;

  List<AppNotification> get items => _items;

  int get unreadCount => _items.where((n) => !n.read).length;

  /// Memuat daftar awal (hanya sekali).
  Future<void> load() async {
    if (_loaded) return;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_loaded) return;
    _items = _mockNotifications();
    _loaded = true;
    notifyListeners();
  }

  /// Tarik-untuk-muat-ulang. Data mock tidak berubah, jadi hanya menunggu sebentar.
  Future<void> refresh() => Future<void>.delayed(const Duration(milliseconds: 400));

  /// Menambah notifikasi baru di urutan teratas (dipakai oleh FCM nanti).
  void add(AppNotification notification) {
    if (_items.any((n) => n.id == notification.id)) return;
    _items = [notification, ..._items];
    notifyListeners();
  }

  void markRead(String id) {
    _items = [
      for (final n in _items) n.id == id ? n.copyWith(read: true) : n,
    ];
    notifyListeners();
  }

  void markAllRead() {
    if (unreadCount == 0) return;
    _items = [for (final n in _items) n.copyWith(read: true)];
    notifyListeners();
  }

  List<AppNotification> _mockNotifications() {
    final now = _now();
    return [
      AppNotification(
        id: 'mock-1',
        title: 'Barang di favoritmu masih tersedia',
        body: 'Sepeda lipat dari Rina masih dijual. Hubungi penjual sebelum keduluan.',
        createdAt: now.subtract(const Duration(minutes: 10)),
        productId: 1,
      ),
      AppNotification(
        id: 'mock-2',
        title: 'Pesan dari penjual',
        body: 'Dimas: Kamera masih ada, silakan dicek langsung ya.',
        createdAt: now.subtract(const Duration(hours: 2)),
        productId: 2,
      ),
      AppNotification(
        id: 'mock-3',
        title: 'Selamat datang di Kulak',
        body: 'Mulai cari barang atau pasang iklan pertamamu lewat tombol Jual.',
        createdAt: now.subtract(const Duration(days: 1)),
        read: true,
      ),
    ];
  }
}