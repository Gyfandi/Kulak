import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../home/data/product.dart';
import '../data/favorites_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = favoritesRepository.ensureLoaded();
  }

  void _retry() {
    setState(() => _loadFuture = favoritesRepository.ensureLoaded());
  }

  Future<void> _remove(Product product) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await favoritesRepository.toggle(product);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Dihapus dari favorit'),
            action: SnackBarAction(
              label: 'Urungkan',
              onPressed: () => favoritesRepository.toggle(product),
            ),
          ),
        );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal menghapus favorit. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorit')),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Memuat favorit...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return _FavoritesError(onRetry: _retry);
          }

          return ListenableBuilder(
            listenable: favoritesRepository,
            builder: (context, _) {
              final items = favoritesRepository.items;
              if (items.isEmpty) return const _FavoritesEmpty();

              return ListView.separated(
                // Padding bawah besar agar tombol "Jual" tidak menutupi item terakhir.
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _FavoriteTile(
                  product: items[index],
                  onOpen: () => context.push('/item/${items[index].id}'),
                  onRemove: () => _remove(items[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.product,
    required this.onOpen,
    required this.onRemove,
  });

  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: product.imageUrl == null || product.imageUrl!.isEmpty
                  ? const _ThumbPlaceholder()
                  : Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _ThumbPlaceholder(),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(product.price),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            product.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Hapus dari favorit',
              onPressed: onRemove,
              icon: Icon(Icons.favorite, color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.inventory_2_outlined, size: 32)),
      );
}

class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 48),
              SizedBox(height: 12),
              Text('Belum ada barang favorit.', textAlign: TextAlign.center),
              SizedBox(height: 4),
              Text(
                'Ketuk ikon hati di halaman detail barang untuk menyimpannya.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _FavoritesError extends StatelessWidget {
  const _FavoritesError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Favorit gagal dimuat. Coba lagi.',
                textAlign: TextAlign.center,
              ),
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