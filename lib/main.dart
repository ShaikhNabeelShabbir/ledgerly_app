import 'package:flutter/material.dart';
import 'package:ledgerly_app/screens/dashboard_screen.dart';
import 'package:ledgerly_app/screens/party_ledger_screen.dart';
import 'package:ledgerly_app/theme/app_theme.dart';
import 'package:ledgerly_app/auth_gate.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ledgerly_app/supabase_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnnonKey,
  );
  runApp(const LedgerlyApp());
}

class LedgerlyApp extends StatelessWidget {
  const LedgerlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ledgerly',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Or force ThemeMode.light based on preference
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/party_ledger': (context) => const PartyLedgerScreen(),
      },
    );
  }
}

