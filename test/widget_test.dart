import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kulak/app.dart';

void main() {
  testWidgets('Aplikasi Kulak berjalan', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KulakApp()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
