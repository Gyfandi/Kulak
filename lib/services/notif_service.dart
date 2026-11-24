import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../pages/detail_demo_page.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseBgHandler(RemoteMessage message) async {
  // Pesan saat app background/terminated ditampilkan oleh sistem (FCM)
}

class NotifService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static void _bukaDetail(String? itemId) {
    if (itemId == null) return;
    navKey.currentState?.push(
      MaterialPageRoute(builder: (_) => DetailDemoPage(itemId: itemId)),
    );
  }

  static Future<void> init() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    debugPrint('FCM TOKEN: ${await fcm.getToken()}');

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) => _bukaDetail(r.payload),
    );

    // Foreground: tampilkan notifikasi manual
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n == null) return;
      _local.show(
        n.hashCode,
        n.title,
        n.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'umum',
            'Umum',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: m.data['item_id'],
      );
    });

    // Background: notifikasi diketuk
    FirebaseMessaging.onMessageOpenedApp
        .listen((m) => _bukaDetail(m.data['item_id']));

    // Terminated: app dibuka dari notifikasi
    final awal = await fcm.getInitialMessage();
    if (awal != null) _bukaDetail(awal.data['item_id']);
  }
}
