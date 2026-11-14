import 'package:flutter/material.dart';

/// Layar sementara. Ganti isinya dengan layar asli sesuai pembagian tugas.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.owner,
    this.actions = const [],
    this.showAppBar = true,
  });

  final String title;
  final String owner;
  final List<Widget> actions;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('Dikerjakan oleh: $owner'),
                const SizedBox(height: 24),
                for (final a in actions) ...[a, const SizedBox(height: 12)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
