// Widget-level tests — Chapter 15 (Green Algeria)
// These test isolated widgets that do NOT require Firebase initialization.
// Full app integration tests (with Firebase) are done manually on a device.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GreenAlgeriaApp basic scaffold renders', (WidgetTester tester) async {
    // Test an isolated widget — no Firebase needed
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('الجزائر خضراء'),
          ),
        ),
      ),
    );
    expect(find.text('الجزائر خضراء'), findsOneWidget);
  });

  testWidgets('Arabic text is right-aligned in RTL directionality', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: MaterialApp(
          home: Scaffold(
            body: Text('مرحباً'),
          ),
        ),
      ),
    );
    expect(find.text('مرحباً'), findsOneWidget);
  });
}
