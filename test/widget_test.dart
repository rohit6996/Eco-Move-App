import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_move/theme/app_theme.dart';
import 'package:eco_move/screens/live_fleet_screen.dart';
import 'package:eco_move/screens/tickets_screen.dart';

void main() {
  testWidgets('LiveFleetScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: LiveFleetScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(LiveFleetScreen), findsOneWidget);
  });

  testWidgets('Tickets screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: TicketsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TicketsScreen), findsOneWidget);
  });
}
