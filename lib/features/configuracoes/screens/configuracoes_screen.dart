// lib/features/configuracoes/screens/configuracoes_screen.dart
import 'package:flutter/material.dart';

// ==================== IMPORTS ====================
import '../../servicos/screens/servico_list_screen.dart';
import '../../pop/screens/pop_views_screen.dart';
import '../../obra/screens/sistema_config_list_screen.dart';
import '../../../features/fase/screens/fase_list_screen.dart';

import '../../obra/screens/obra_pisos_screen.dart';

// Ambientes Globais
import '../../ambiente/screens/ambiente_list_screen.dart';

// NOVO: Backup Global
import '../../backup/screens/backup_history_screen.dart';

import '../../parceiros/screens/arquitetos_list_screen.dart';
import '../../parceiros/screens/construtoras_list_screen.dart';

import '../../filial/screens/filiais_list_screen.dart';

import '../../obra/screens/categoria_list_screen.dart';

import '../../pop/screens/pops_list_screen.dart';
import '../../pop/screens/categorias_manager_screen.dart';
import '../../pop/screens/pops_dashboard_screen.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  Widget? _currentScreen;
  String _currentTitle = "Configurações";

  @override
  void initState() {
    super.initState();
    _currentScreen = const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 80, color: Colors.grey),
          SizedBox(height: 24),
          Text("Configurações Gerais do Sistema", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          SizedBox(height: 8),
          Text("Selecione uma opção no menu lateral", style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
    _currentTitle = "Geral";
  }

  void _changeScreen(Widget screen, String title) {
    setState(() {
      _currentScreen = screen;
      _currentTitle = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Configurações - $_currentTitle"),
        backgroundColor: Colors.teal[900],
      ),
      body: Row(
        children: [
          // MENU LATERAL
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // ==================== OBRAS ====================
                ExpansionTile(
                  initiallyExpanded: false,
                  leading: const Icon(Icons.home_work, color: Colors.teal),
                  title: const Text("Obras", style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    ListTile(
                      title: const Text("Sistemas"),
                      onTap: () => _changeScreen(const SistemaConfigListScreen(), "Sistemas"),
                    ),
                    ListTile(
                      title: const Text("Serviços"),
                      leading: const Icon(Icons.build_circle, color: Colors.orange),
                      onTap: () => _changeScreen(const ServicoListScreen(), "Serviços"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.layers_outlined, size: 20),
                      title: const Text("Pavimentos"),
                      onTap: () => _changeScreen(const ObraPisosScreen(titulo: "Gerenciar Pavimentos"), "Pavimentos"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.room_outlined, size: 20),
                      title: const Text("Ambientes Globais"),
                      onTap: () => _changeScreen(const AmbienteListScreen(), "Ambientes Globais"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.flag_outlined, size: 20),
                      title: const Text("Fases"),
                      onTap: () => _changeScreen(const FaseListScreen(), "Fases"),
                    ),
                    // ==================== NOVO: BACKUP GLOBAL ====================
                    ListTile(
                      leading: const Icon(Icons.backup, color: Colors.indigo),
                      title: const Text("Histórico de Backups"),
                      subtitle: const Text("Proteção e Restauração"),
                      onTap: () => _changeScreen(const BackupHistoryScreen(), "Backups"),
                    ),
                  ],
                ),

                const Divider(),

                // ==================== PRODUTOS ====================
                ExpansionTile(
                  initiallyExpanded: false,
                  leading: const Icon(Icons.inventory_2, color: Colors.deepPurple),
                  title: const Text("Produtos", style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    ListTile(
                      title: const Text("Categorias"),
                      leading: const Icon(Icons.label, size: 20),
                      onTap: () => _changeScreen(const CategoriaListScreen(), "Categorias"),
                    ),
                  ],
                ),

                const Divider(),

                // ==================== PARCEIROS ====================
                ExpansionTile(
                  initiallyExpanded: false,
                  leading: const Icon(Icons.people, color: Colors.orange),
                  title: const Text("Parceiros", style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    ListTile(title: const Text("Arquitetos"), onTap: () => _changeScreen(const ArquitetosListScreen(), "Arquitetos")),
                    ListTile(title: const Text("Construtoras"), onTap: () => _changeScreen(const ConstrutorasListScreen(), "Construtoras")),
                  ],
                ),

                const Divider(),

                // ==================== FILIAIS ====================
                ExpansionTile(
                  initiallyExpanded: false,
                  leading: const Icon(Icons.business, color: Colors.indigo),
                  title: const Text("Filiais", style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    ListTile(
                      title: const Text("Gerenciar Filiais"),
                      onTap: () => _changeScreen(const FiliaisListScreen(), "Filiais"),
                    ),
                  ],
                ),

                const Divider(),

                // ==================== POPs ====================
                ExpansionTile(
                  initiallyExpanded: false,
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text("POPs", style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dashboard, size: 20),
                      title: const Text("Dashboard de POPs"),
                      onTap: () => _changeScreen(const PopsDashboardScreen(), "Dashboard POPs"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.list_alt, size: 20),
                      title: const Text("Gerenciar POPs"),
                      onTap: () => _changeScreen(const PopsListScreen(), "POPs"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // CONTEÚDO PRINCIPAL
          Expanded(
            child: Container(
              color: Colors.white,
              child: _currentScreen ?? const Center(child: Text("Selecione uma opção")),
            ),
          ),
        ],
      ),
    );
  }
}