// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart' as date_symbol;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Providers
import 'models/sac_call.dart';
import 'providers/employee_provider.dart';
import 'providers/branch_provider.dart';
import 'providers/ponto_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/travel_provider.dart';
import 'providers/client_provider.dart';
import 'providers/client_phase_config_provider.dart';
import 'providers/architect_provider.dart';
import 'providers/constructor_provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/brand_provider.dart';
import 'providers/category_provider.dart';
import 'providers/unit_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/birthday_message_provider.dart';
import 'providers/attendment_provider.dart';
import 'providers/client_pendency_provider.dart';
import 'providers/sac_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/company_provider.dart';
import 'providers/checklist_provider.dart';
import 'providers/tool_catalog_provider.dart';

// Telas
import 'screens/auth/auth_wrapper.dart';
import 'screens/sac/sac_execution_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await date_symbol.initializeDateFormatting('pt_BR', null);

  // ==================== NOVO SUPABASE ====================
  await Supabase.initialize(
    url: 'https://atswwiskotduecvmogku.supabase.co',           // ← MUDE AQUI
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0c3d3aXNrb3RkdWVjdm1vZ2t1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMzgxMTAsImV4cCI6MjA5MzkxNDExMH0.SMNLiCRMAXVKjONQxAOwVuDN31Jv-AUxy6FoF4tyO-o',       // ← MUDE AQUI
    debug: false,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => PontoProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => TravelProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => ClientPhaseConfigProvider()),
        ChangeNotifierProvider(create: (_) => ArchitectProvider()),
        ChangeNotifierProvider(create: (_) => ConstructorProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()),
        ChangeNotifierProvider(create: (_) => BrandProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => UnitProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => BirthdayMessageProvider()),
        ChangeNotifierProvider(create: (_) => AttendmentProvider()),
        ChangeNotifierProvider(create: (_) => ClientPendencyProvider()),
        ChangeNotifierProvider(create: (_) => SacProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => ChecklistProvider()),
        ChangeNotifierProvider(create: (_) => ToolCatalogProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satiro One',                    // ← Nome novo
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],

      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/sac_execution': (context) {
          final call = ModalRoute.of(context)!.settings.arguments as SacCall;
          return SacExecutionScreen(call: call);
        },
      },

      onUnknownRoute: (settings) {
        print('❌ Rota não encontrada: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Rota não encontrada')),
          ),
        );
      },
    );
  }
}