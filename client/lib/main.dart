import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'widgets/main_layout.dart';
import 'screens/auth_screen.dart';
import 'screens/doctor_prescription_screen.dart';
import 'screens/pharmacist_dispense_screen.dart';
import 'screens/patient_interactive_screen.dart';
import 'screens/insurance_portal_screen.dart';
import 'screens/hospitals_screen.dart';
import 'screens/dashboard_overview_screen.dart';
import 'screens/my_medicines_screen.dart';
import 'screens/prescriptions_screen.dart';
import 'screens/prescription_details_screen.dart';
import 'screens/health_records_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/formulary_screen.dart';
import 'screens/friction_screen.dart';
import 'screens/admin_data_users_screen.dart';
import 'screens/admin_reports_screen.dart';
import 'screens/voice_agent_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService().initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const AlterneaApp(),
    ),
  );
}

class AlterneaApp extends StatelessWidget {
  const AlterneaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alternea - Healthcare & Prescription Ecosystem',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    if (!appState.isLoggedIn) {
      return const AuthScreen();
    }

    Widget activeScreen;

    if (user.isDoctor) {
      switch (appState.currentNavIndex) {
        case 0:
          activeScreen = const DoctorPrescriptionScreen();
          break;
        case 1:
          activeScreen = const HealthRecordsScreen();
          break;
        case 2:
          activeScreen = const HospitalsScreen();
          break;
        case 3:
          activeScreen = const DashboardOverviewScreen();
          break;
        case 4:
          activeScreen = const VoiceAgentScreen();
          break;
        default:
          activeScreen = const DoctorPrescriptionScreen();
      }
    } else if (user.isPharmacist) {
      switch (appState.currentNavIndex) {
        case 0:
          activeScreen = const PharmacistDispenseScreen();
          break;
        case 1:
          if (appState.selectedPrescriptionId != null) {
            activeScreen = PrescriptionDetailsScreen(
              prescriptionId: appState.selectedPrescriptionId!,
            );
          } else {
            activeScreen = const PrescriptionsScreen();
          }
          break;
        case 2:
          activeScreen = const DashboardOverviewScreen();
          break;
        case 3:
          activeScreen = const FormularyScreen();
          break;
        case 4:
          activeScreen = const VoiceAgentScreen();
          break;
        default:
          activeScreen = const PharmacistDispenseScreen();
      }
    } else if (user.isPatient) {
      switch (appState.currentNavIndex) {
        case 0:
          activeScreen = const PatientInteractiveScreen();
          break;
        case 1:
          activeScreen = const MyMedicinesScreen();
          break;
        case 2:
          activeScreen = const HospitalsScreen();
          break;
        case 3:
          activeScreen = const VoiceAgentScreen();
          break;
        default:
          activeScreen = const PatientInteractiveScreen();
      }
    } else if (user.isInsuranceAgent) {
      switch (appState.currentNavIndex) {
        case 0:
          activeScreen = const InsurancePortalScreen();
          break;
        case 1:
          activeScreen = const FormularyScreen();
          break;
        case 2:
          activeScreen = const FrictionScreen();
          break;
        case 3:
          activeScreen = const VoiceAgentScreen();
          break;
        default:
          activeScreen = const InsurancePortalScreen();
      }
    } else {
      // Admin Role
      switch (appState.currentNavIndex) {
        case 0:
          activeScreen = const DashboardScreen();
          break;
        case 1:
          activeScreen = const HospitalsScreen();
          break;
        case 2:
          activeScreen = const HealthRecordsScreen();
          break;
        case 3:
          activeScreen = const AdminDataUsersScreen();
          break;
        case 4:
          activeScreen = const DashboardOverviewScreen();
          break;
        case 5:
          activeScreen = const AdminReportsScreen();
          break;
        case 6:
          activeScreen = const VoiceAgentScreen();
          break;
        default:
          activeScreen = const DashboardScreen();
      }
    }

    return MainLayout(
      child: activeScreen,
    );
  }
}
