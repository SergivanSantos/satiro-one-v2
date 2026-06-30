// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart' as date_symbol;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==================== PROVIDERS ATIVOS ====================
import 'features/ambiente/providers/ambiente_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/backup/providers/backup_provider.dart';
import 'features/client/providers/cliente_provider.dart';
import 'features/fase/providers/fase_provider.dart';
import 'features/filial/providers/filial_provider.dart';
import 'features/obra/providers/obra_provider.dart';
import 'features/obra/providers/obra_wizard_provider.dart';
import 'features/os/providers/os_provider.dart';
import 'features/parceiros/providers/parceiros_provider.dart';
import 'features/pop/providers/pop_provider.dart';
import 'features/rh/providers/employee_provider.dart';
import 'features/servicos/providers/servico_provider.dart';



// ==================== TELAS ====================
import 'features/auth/screens/auth_wrapper.dart';
import 'features/obra/screens/obra_wizard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await date_symbol.initializeDateFormatting('pt_BR', null);

  await Supabase.initialize(
    url: 'https://atswwiskotduecvmogku.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0c3d3aXNrb3RkdWVjdm1vZ2t1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMzgxMTAsImV4cCI6MjA5MzkxNDExMH0.SMNLiCRMAXVKjONQxAOwVuDN31Jv-AUxy6FoF4tyO-o',
    debug: false,
  );

  runApp(
    MultiProvider(
      providers: [
        // Core / Auth
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),

        // Features Ativas
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => FilialProvider()),
        ChangeNotifierProvider(create: (_) => ObraProvider()),
        ChangeNotifierProvider(create: (_) => ObraWizardProvider()),
        ChangeNotifierProvider(create: (_) => ParceirosProvider()),
        ChangeNotifierProvider(create: (_) => PopProvider()),
        ChangeNotifierProvider(create: (_) => ServicoProvider()),
        ChangeNotifierProvider(create: (_) => OsProvider()),
        ChangeNotifierProvider(create: (_) => FaseProvider()),
        ChangeNotifierProvider(create: (_) => AmbienteProvider()),
        ChangeNotifierProvider(create: (_) => BackupProvider()),


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
      title: 'Satiro One',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,

        // ==================== CORES PRINCIPAIS ====================
        scaffoldBackgroundColor: Colors.grey[50],

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00695C), // teal[900]
          foregroundColor: Colors.white,
          elevation: 2,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        // ==================== TEXTOS ====================
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),

        // ==================== CARDS ====================
        cardTheme: CardThemeData(          // ← Corrigido aqui
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
        ),

        // ==================== BOTÕES ====================
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // ==================== INPUTS ====================
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),

        // ==================== CHIPS ====================
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[200],
          selectedColor: Colors.teal[100],
          labelStyle: const TextStyle(color: Colors.black87),
        ),
      ),

      // ==================== LOCALIZAÇÃO ====================
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],

      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/nova_obra': (context) => const ObraWizardScreen(),
      },

      onUnknownRoute: (settings) {
        debugPrint('❌ Rota não encontrada: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Rota não encontrada')),
          ),
        );
      },
    );
  }
}