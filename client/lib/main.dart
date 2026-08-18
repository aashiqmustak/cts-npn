import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/main_layout.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_overview_screen.dart';
import 'screens/my_medicines_screen.dart';
import 'screens/prescriptions_screen.dart';
import 'screens/prescription_details_screen.dart';
import 'screens/health_records_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PharmaAssistApp(),
    ),
  );
}

class PharmaAssistApp extends StatelessWidget {
  const PharmaAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PharmaAssist - Smarter Medication Decisions',
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

    // If user is not logged in, render Login & Register Screen
    if (!appState.isLoggedIn) {
      return const AuthScreen();
    }

    // Dynamic Navigation Router for Sidebar Links
    Widget activeScreen;

    switch (appState.currentNavIndex) {
      case 0:
        activeScreen = const DashboardOverviewScreen();
        break;
      case 1:
        activeScreen = const MyMedicinesScreen();
        break;
      case 2:
        if (appState.selectedPrescriptionId != null) {
          activeScreen = PrescriptionDetailsScreen(
            prescriptionId: appState.selectedPrescriptionId!,
          );
        } else {
          activeScreen = const PrescriptionsScreen();
        }
        break;
      case 3:
        activeScreen = const MyMedicinesScreen();
        break;
      case 4:
        activeScreen = const DashboardScreen();
        break;
      case 5:
        activeScreen = const DashboardOverviewScreen();
        break;
      case 6:
        activeScreen = const HealthRecordsScreen();
        break;
      case 7:
        activeScreen = const DashboardOverviewScreen();
        break;
      case 8:
        activeScreen = const DashboardOverviewScreen();
        break;
      default:
        activeScreen = const DashboardOverviewScreen();
    }

    // Main App Layout Shell
    return MainLayout(
      child: activeScreen,
    );
  }
}
