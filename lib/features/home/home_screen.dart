// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../rh/providers/employee_provider.dart';

// Telas principais
import '../obra/screens/obra_list_screen.dart';
import '../client/screens/clientes_list_screen.dart';
import '../rh/screens/employee_list_screen.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../configuracoes/screens/configuracoes_screen.dart';

// Telas específicas do técnico
import '../obra/screens/tecnico_home_screen.dart';

// Telas de chamados
import '../chamado/screens/chamado_list_admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final employee = employeeProvider.currentEmployee;

    // Se for técnico → vai direto para a tela dele
    if (employee?.isTecnico == true) {
      return const TecnicoHomeScreen();
    }

    // Admin / Gerente / RH → menu completo
    final userName = employee?.name?.split(' ').first ?? 'Usuário';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        title: const Text("Satiro One", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.orange[400],
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.dashboard, size: 18), text: "Dashboard"),
              Tab(icon: Icon(Icons.home_work, size: 18), text: "Obras"),
              Tab(icon: Icon(Icons.people, size: 18), text: "Clientes"),
              Tab(icon: Icon(Icons.group, size: 18), text: "Equipe"),
              Tab(icon: Icon(Icons.assignment, size: 18), text: "Chamados"),
              Tab(icon: Icon(Icons.settings, size: 18), text: "Config."),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "Olá, $userName",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sair?'),
                  content: const Text('Deseja realmente sair?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sair', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await employeeProvider.logout();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardScreen(),
          ObraListScreen(),
          ClientesListScreen(),
          EmployeeListScreen(),
          ChamadoListAdminScreen(),
          ConfiguracoesScreen(),
        ],
      ),
    );
  }
}