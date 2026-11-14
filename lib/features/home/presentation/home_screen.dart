import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/placeholder_screen.dart';

// TODO(Khairus): beranda (katalog barang, grid 2 kolom).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Beranda',
      owner: 'Khairus',
      actions: [
        FilledButton(
          onPressed: () => context.push('/item/1'),
          child: const Text('Buka detail barang (contoh)'),
        ),
      ],
    );
  }
}
