import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

// TODO(Khairus): detail barang. Adi menambahkan tombol "Hubungi Penjual".
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(title: 'Detail Barang #$id', owner: 'Khairus dan Adi');
  }
}
