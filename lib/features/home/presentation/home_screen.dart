import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/api/api_exception.dart';
import '../data/catalog_repository.dart';
import '../data/catalog_service.dart';
import '../data/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = catalogRepository.getProducts();
  }

  Future<void> _reload() async {
    final request = catalogRepository.getProducts();
    setState(() => _productsFuture = request);
    try {
      await request;
    } catch (_) {
      // FutureBuilder renders the error state, while RefreshIndicator completes.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: Column(
        children: [
          const _NetworkStatusBanner(),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Memuat katalog...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _CatalogError(
                    error: snapshot.error,
                    onRetry: () => _reload(),
                  );
                }

                final products = snapshot.data ?? const <Product>[];
                if (products.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      children: const [
                        SizedBox(height: 140),
                        Center(child: Text('Belum ada barang yang tersedia.')),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: .68,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) => _ProductCard(
                      product: products[index],
                      onTap: () => context.push('/item/${products[index].id}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: product.imageUrl == null || product.imageUrl!.isEmpty
                    ? const _ImagePlaceholder()
                    : Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _ImagePlaceholder(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _rupiah(product.price),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          product.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.inventory_2_outlined, size: 42)),
      );
}

class _NetworkStatusBanner extends StatelessWidget {
  const _NetworkStatusBanner();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.contains(ConnectivityResult.none)) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.errorContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: const Text('Offline · menampilkan data tersimpan jika tersedia'),
        );
      },
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  String get _message {
    if (error is CatalogOfflineException) {
      return 'Kamu sedang offline dan belum ada data tersimpan.';
    }
    if (error is CatalogTimeoutException) {
      return 'Permintaan melewati batas waktu. Coba lagi.';
    }
    if (error is ApiException) {
      final apiError = error! as ApiException;
      return switch (apiError.statusCode) {
        401 => 'Sesi login berakhir. Silakan login kembali.',
        404 => 'Barang yang diminta tidak ditemukan.',
        500 => 'Server sedang bermasalah. Coba lagi nanti.',
        _ when apiError.statusCode == null => 'Koneksi atau server tidak merespons. Periksa internet lalu coba lagi.',
        _ => apiError.message,
      };
    }
    if (error is FormatException) return 'Format data katalog dari server belum sesuai.';
    return 'Katalog gagal dimuat. Coba lagi.';
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              Text(_message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
}

String _rupiah(int amount) =>
    'Rp ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
