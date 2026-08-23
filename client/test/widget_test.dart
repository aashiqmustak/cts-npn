import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:client/main.dart';
import 'package:client/models/models.dart';
import 'package:client/providers/app_state.dart';

void main() {
  testWidgets('Alternea app loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const AlterneaApp(),
      ),
    );

    expect(find.text('Alternea'), findsWidgets);
  });

  testWidgets('Patients with incomplete profiles are routed to profile completion', (WidgetTester tester) async {
    final appState = AppState();
    addTearDown(appState.dispose);
    appState.login(
      const User(
        id: 'PT-1001',
        name: 'Alicia Gomez',
        email: 'alicia@example.com',
        role: UserRole.patient,
        title: 'Patient Account',
        hospitalId: 'HOSP-101',
        hospitalName: 'MetroHealth Medical Center',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: AppShell(),
        ),
      ),
    );

    expect(find.text('Complete Your Profile'), findsOneWidget);
    appState.cancelAllFollowUpTimers();
  });
}
