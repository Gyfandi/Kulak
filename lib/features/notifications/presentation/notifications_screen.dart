import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/format.dart';
import '../data/notifications_repository.dart';
import '../data/notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = notificationsRepository.load();
  }

  void _retry() {
    setState(() => _loadFuture = notificationsRepository.load());
  }

  void _open(AppNotification item) {
    notificationsRepository.markRead(item.id);
    final productId = item.productId;
    if (productId != null) context.push('/item/$productId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          ListenableBuilder(
            listenable: notificationsRepository,
            builder: (context, _) => TextButton(
              onPressed: notificationsRepository.unreadCount == 0
                  ? null
                  : notificationsRepository.markAllRead,
              child: const Text('Tandai dibaca'),
            ),
          ),
        ],
      ),
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
                  Text('Memuat notifikasi...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return _NotificationsError(onRetry: _retry);
          }

          return ListenableBuilder(
            listenable: notificationsRepository,
            builder: (context, _) {
              final items = notificationsRepository.items;
              return RefreshIndicator(
                onRefresh: notificationsRepository.refresh,
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 140),
                          Center(child: Text('Belum ada notifikasi.')),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        // Padding bawah besar agar tombol "Jual" tidak menutupi item terakhir.
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) => _NotificationTile(
                          item: items[index],
                          onTap: () => _open(items[index]),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          item.read ? Icons.notifications_none : Icons.notifications_active,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        item.title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: item.read ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${item.body}\n${timeAgo(item.createdAt)}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      isThreeLine: true,
      trailing: item.read
          ? null
          : Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  const _NotificationsError({required this.onRetry});

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
                'Notifikasi gagal dimuat. Coba lagi.',
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