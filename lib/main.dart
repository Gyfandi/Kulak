import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'pages/beranda_demo_page.dart';
import 'services/notif_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBgHandler);
    await NotifService.init();
  } catch (e) {
    debugPrint('Firebase belum dikonfigurasi: $e');
  }
  runApp(const KulakApp());
}

class KulakApp extends StatelessWidget {
  const KulakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kulak',
      navigatorKey: navKey,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const BerandaDemoPage(),
    );
  }
}
