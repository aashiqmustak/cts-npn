import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/models/models.dart';
import 'package:client/providers/app_state.dart';
import 'package:client/screens/patient_interactive_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Patient Prescriptions & Follow-up Unit Tests', () {
    test('Prescription model status and copyWith helper tests', () {
      final rx = Prescription(
        id: 'RX-1001',
        patientId: 'PT-301',
        patientName: 'Eleanor Vance',
        drugId: 'DRUG-01',
        drugName: 'Metformin HCL',
        drugClass: 'Cardiovascular / Endocrine',
        fillDates: [],
        fillRecords: [],
        pdcScore: 0.85,
        status: 'Prescribed',
        lastFillDate: DateTime(2026, 8, 20),
        nextDueDate: DateTime(2026, 9, 20),
        prescriberName: 'Dr. Tariq Martin',
        prescribedDate: DateTime(2026, 8, 23),
        notes: 'Take 500mg twice daily with meals',
      );

      expect(rx.isBought, isFalse);
      expect(rx.isNotBought, isFalse);

      final boughtRx = rx.copyWith(status: 'Bought');
      expect(boughtRx.isBought, isTrue);
      expect(boughtRx.isNotBought, isFalse);

      final notBoughtRx = rx.copyWith(status: 'Not Bought');
      expect(notBoughtRx.isBought, isFalse);
      expect(notBoughtRx.isNotBought, isTrue);
    });

    test('AppState markPrescriptionBought updates status to Bought', () async {
      final appState = AppState();

      // Issue test prescription
      await appState.createDoctorPrescription(
        patientId: 'PT-301',
        doctorId: 'DOC-201',
        hospitalId: 'HOSP-101',
        diagnosis: 'Type 2 Diabetes Mellitus',
        notes: 'Take with morning and evening meals',
        items: [
          {
            'medicineName': 'Metformin 500mg',
            'dosage': '500 mg',
            'frequency': 'Twice daily',
            'durationDays': 30,
            'instructions': 'Take with meals',
          }
        ],
      );

      final rx = appState.prescriptions.first;
      await appState.markPrescriptionBought(rx.id);

      final updatedRx = appState.prescriptions.firstWhere((r) => r.id == rx.id);
      expect(updatedRx.status, equals('Bought'));
      expect(updatedRx.isBought, isTrue);
    });

    test('AppState markPrescriptionNotBought updates status to Not Bought', () async {
      final appState = AppState();

      await appState.createDoctorPrescription(
        patientId: 'PT-301',
        doctorId: 'DOC-201',
        hospitalId: 'HOSP-101',
        diagnosis: 'Hypertension',
        notes: 'Take once daily in morning',
        items: [
          {
            'medicineName': 'Lisinopril 10mg',
            'dosage': '10 mg',
            'frequency': 'Once daily',
            'durationDays': 30,
            'instructions': 'Take in morning',
          }
        ],
      );

      final rx = appState.prescriptions.first;
      await appState.markPrescriptionNotBought(rx.id);

      final updatedRx = appState.prescriptions.firstWhere((r) => r.id == rx.id);
      expect(updatedRx.status, equals('Not Bought'));
      expect(updatedRx.isNotBought, isTrue);

      appState.cancelAllFollowUpTimers();
      appState.dispose();
    });

    test('AppState logout clears session, state, timers and sets isLoggedIn to false', () {
      final appState = AppState();
      appState.login(
        const User(
          id: 'PT-301',
          name: 'Eleanor Vance',
          email: 'eleanor@example.com',
          role: UserRole.patient,
          patientId: 'PT-301',
          assignedPatientIds: [],
          title: 'Patient Account',
        ),
      );

      expect(appState.isLoggedIn, isTrue);

      appState.logout();

      expect(appState.isLoggedIn, isFalse);
      expect(appState.currentNavIndex, equals(0));
      expect(appState.activeSubTabIndex, equals(0));
      expect(appState.selectedPrescriptionId, isNull);
      expect(appState.activeFollowUpIncomingCall, isNull);

      appState.dispose();
    });

    test('AppState signInWithGooglePatient creates active patient with complete profile', () async {
      final appState = AppState();

      await appState.signInWithGooglePatient();

      expect(appState.isLoggedIn, isTrue);
      expect(appState.currentUser.role, equals(UserRole.patient));
      expect(appState.currentUser.name, isNotEmpty);
      expect(appState.isPatientProfileComplete, isTrue);

      appState.dispose();
    });

    test('AppState sendOtp handles PAT_00001 identifier smoothly', () async {
      final appState = AppState();

      final res = await appState.sendOtp('PAT_00001');
      expect(res, isTrue);

      appState.dispose();
    });
  });

  group('Patient Prescriptions UI Widget Tests', () {
    testWidgets('Renders My Prescriptions section with all required fields and buttons', (WidgetTester tester) async {
      final appState = AppState();
      appState.login(
        const User(
          id: 'PT-301',
          name: 'Eleanor Vance',
          email: 'eleanor@example.com',
          role: UserRole.patient,
          patientId: 'PT-301',
          assignedPatientIds: [],
          title: 'Patient Account',
          hospitalId: 'HOSP-101',
          hospitalName: 'MetroHealth Medical Center',
        ),
      );

      await appState.createDoctorPrescription(
        patientId: 'PT-301',
        doctorId: 'DOC-201',
        hospitalId: 'HOSP-101',
        diagnosis: 'Hypertension Stage 1',
        notes: 'Take 1 tablet every morning with a full glass of water',
        items: [
          {
            'medicineName': 'Amlodipine Besylate 5mg',
            'dosage': '5 mg',
            'frequency': 'Once daily (Morning)',
            'durationDays': 30,
            'instructions': 'Take 1 tablet every morning with a full glass of water',
          }
        ],
      );

      // Set desktop window size to avoid flex overflows
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const Scaffold(
              body: PatientInteractiveScreen(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // 1. Verify "My Prescriptions" section title
      expect(find.text('My Prescriptions'), findsOneWidget);

      // 2. Verify Doctor Name
      expect(find.textContaining('Dr. Tariq Martin'), findsWidgets);

      // 3. Verify Medication Name
      expect(find.text('Amlodipine Besylate 5mg'), findsWidgets);

      // 4. Verify Dosage
      expect(find.text('5 mg'), findsWidgets);

      // 5. Verify Frequency
      expect(find.text('Once daily (Morning)'), findsWidgets);

      // 6. Verify Duration
      expect(find.text('30 Days'), findsWidgets);

      // 7. Verify Instructions
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Take 1 tablet every morning'),
        ),
        findsWidgets,
      );

      // 8. Verify Action Buttons: ✓ Bought | ✕ Not Bought
      expect(find.text('✓ Bought'), findsOneWidget);
      expect(find.text('✕ Not Bought'), findsOneWidget);

      // 9. Tap "✓ Bought" -> verifies status updates and snack bar shows
      await tester.tap(find.text('✓ Bought'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Prescription marked as bought.'), findsOneWidget);
      expect(find.text('Bought'), findsWidgets);

      // 10. Tap "✕ Not Bought" -> verifies follow-up snack bar shows
      await tester.tap(find.text('✕ Not Bought'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Follow-up call will be initiated shortly.'), findsOneWidget);

      appState.cancelAllFollowUpTimers();
      appState.dispose();
    });
  });
}
