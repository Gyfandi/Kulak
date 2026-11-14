import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/placeholder_screen.dart';

// TODO(Farel): profil, tab "Iklan Saya", logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Profil',
      owner: 'Farel',
      actions: [
        OutlinedButton(
          onPressed: () => context.go('/login'),
          child: const Text('Keluar'),
        ),
      ],
    );
  }
}
