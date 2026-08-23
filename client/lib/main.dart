import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'providers/app_state.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'widgets/main_layout.dart';
import 'screens/auth_screen.dart';
import 'screens/patient_profile_completion_screen.dart';

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

    if (!appState.isLoggedIn) {
      return const AuthScreen();
    }

    if (appState.currentUser.role == UserRole.patient && !appState.isPatientProfileComplete) {
      return const PatientProfileCompletionScreen();
    }

    return const MainLayout();
  }
}
