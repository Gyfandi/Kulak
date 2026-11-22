import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/api_exception.dart';
import '../../favorites/data/favorites_service.dart';
import '../data/catalog_repository.dart';
import '../data/catalog_service.dart';
import '../data/product.dart';
import '../data/seller_contact.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Future<Product> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = catalogRepository.getProduct(widget.id);
  }

  @override
  void didUpdateWidget(covariant ItemDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _productFuture = catalogRepository.getProduct(widget.id);
    }
  }

  Future<void> _reload() async {
    final request = catalogRepository.getProduct(widget.id);
    setState(() => _productFuture = request);
    try {
      await request;
    } catch (_) {
      // FutureBuilder renders the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _productFuture,
      builder: (context, snapshot) {
        final product = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail barang'),
            actions: product == null
                ? null
                : [
                    _FavoriteButton(product: product),
                    _MoreMenu(product: product),
                  ],
          ),
          body: _buildBody(snapshot),
          bottomNavigationBar:
              product == null ? null : _ContactBar(product: product),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<Product> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return _DetailError(error: snapshot.error, onRetry: _reload);
    }
    return _ProductDetails(product: snapshot.data!);
  }
}

/// Tombol hati: simpan/hapus barang dari favorit.
class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.product});

  final Product product;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  @override
  void initState() {
    super.initState();
    // Muat daftar favorit supaya status hati sesuai; kegagalan ditangani saat ditekan.
    favoritesRepository.ensureLoaded().catchError((Object _) {});
  }

  Future<void> _toggle() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final added = await favoritesRepository.toggle(widget.product);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              added ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit',
            ),
          ),
        );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan favorit. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: favoritesRepository,
      builder: (context, _) {
        final isFavorite = favoritesRepository.isFavorite(widget.product.id);
        return IconButton(
          tooltip: isFavorite ? 'Hapus dari favorit' : 'Tambah ke favorit',
          onPressed: _toggle,
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Theme.of(context).colorScheme.error : null,
          ),
        );
      },
    );
  }
}

/// Menu titik tiga: laporkan barang.
class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Menu lainnya',
      onSelected: (value) {
        if (value == 'report') {
          context.push('/report/${product.id}', extra: product.name);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'report', child: Text('Laporkan barang')),
      ],
    );
  }
}

/// Bilah bawah: telepon dan WhatsApp ke penjual.
class _ContactBar extends StatelessWidget {
  const _ContactBar({required this.product});

  final Product product;

  Future<void> _open(BuildContext context, Uri uri, String failMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await openExternal(uri);
    if (opened) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final phone = normalizeIndonesianPhone(product.sellerPhone);
    final message =
        'Halo, saya tertarik dengan "${product.name}" di Kulak. Apakah masih tersedia?';

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phone == null
                    ? 'Nomor penjual belum tersedia.'
                    : 'Hubungi penjual',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: phone == null
                          ? null
                          : () => _open(
                                context,
                                telUri(phone),
                                'Tidak bisa membuka aplikasi telepon di perangkat ini.',
                              ),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Telepon'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: phone == null
                          ? null
                          : () => _open(
                                context,
                                whatsappUri(phone, message),
                                'WhatsApp tidak bisa dibuka di perangkat ini.',
                              ),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: product.imageUrl == null || product.imageUrl!.isEmpty
                ? const ColoredBox(
                    color: Color(0xFFE8EFED),
                    child: Center(child: Icon(Icons.inventory_2_outlined, size: 72)),
                  )
                : Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const ColoredBox(
                      color: Color(0xFFE8EFED),
                      child: Center(child: Icon(Icons.broken_image_outlined, size: 64)),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          _rupiah(product.price),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.location_on_outlined),
            const SizedBox(width: 6),
            Text(product.location),
          ],
        ),
        const Divider(height: 32),
        Text('Deskripsi', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(product.description.isEmpty ? 'Belum ada deskripsi.' : product.description),
        const Divider(height: 32),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(product.sellerName),
          subtitle: const Text('Penjual'),
        ),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  String get _message {
    if (error is CatalogOfflineException) {
      return 'Kamu sedang offline dan detail barang belum tersimpan.';
    }
    if (error is CatalogTimeoutException) {
      return 'Permintaan melewati batas waktu. Coba lagi.';
    }
    if (error is ApiException) {
      final apiError = error! as ApiException;
      return switch (apiError.statusCode) {
        401 => 'Sesi login berakhir. Silakan login kembali.',
        404 => 'Barang tidak ditemukan atau sudah dihapus.',
        500 => 'Server sedang bermasalah. Coba lagi nanti.',
        _ when apiError.statusCode == null => 'Koneksi atau server tidak merespons. Periksa internet lalu coba lagi.',
        _ => apiError.message,
      };
    }
    return 'Detail barang gagal dimuat.';
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
}

String _rupiah(int amount) =>
    'Rp ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';