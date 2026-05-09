// dashboard_web/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/employee.dart';
import 'providers/employee_provider.dart';
import 'screens/dashboard_home_screen.dart'; // ← sua tela de rotação

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR');

  await Supabase.initialize(
    url: 'https://tzhulvzsmlqeamkhyftk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6aHVsdnpzbWxxZWFta2h5ZnRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNjU0MjQsImV4cCI6MjA4Mjk0MTQyNH0.U0NEgn9Ls2aXI713BDZp_WBqDYTjRDabQg_N1gDcwlg',
  );

  runApp(const DashboardWebApp());
}

class DashboardWebApp extends StatelessWidget {
  const DashboardWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmployeeProvider(),
      child: MaterialApp(
        title: 'Satiro One - Dashboard Corporativo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
          scaffoldBackgroundColor: Colors.grey[900],
        ),
        home: const DashboardHomeScreen(), // ← aqui inicia o multi-telas
      ),
    );
  }
}