import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/placeholder_screen.dart';

// TODO(Farel): ganti dengan layar login sesuai desain Figma.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Login',
      owner: 'Farel',
      showAppBar: false,
      actions: [
        FilledButton(
          onPressed: () => context.go('/home'),
          child: const Text('Masuk'),
        ),
        OutlinedButton(
          onPressed: () => context.push('/register'),
          child: const Text('Daftar sekarang'),
        ),
      ],
    );
  }
}
