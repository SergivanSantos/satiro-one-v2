import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../obra/providers/ordem_servico_provider.dart';
import '../../providers/chamado_provider.dart';
import '../../../rh/providers/employee_provider.dart';
import '../../../obra/providers/obra_provider.dart';
import '../../../client/providers/cliente_provider.dart';
import '../../../filial/providers/filial_provider.dart';
import '../../../servicos/providers/servico_provider.dart';

import '../chamado_form_screen.dart';
import 'tabs/today_tab.dart';
import 'tabs/week_tab.dart';
import 'tabs/by_technician_tab.dart';
import 'tabs/by_obra_tab.dart';
import 'tabs/pendentes_tab.dart';
import 'widgets/summary_cards.dart';

class ChamadoListAdminScreen extends StatefulWidget {
  const ChamadoListAdminScreen({super.key});

  @override
  State<ChamadoListAdminScreen> createState() => _ChamadoListAdminScreenState();
}

class _ChamadoListAdminScreenState extends State<ChamadoListAdminScreen> {
  int _currentTab = 0;
  String? _selectedFilialId;

  Future<void> _carregarDados() async {
    final ordemProvider = context.read<OrdemServicoProvider>();

    await Future.wait([
      context.read<ChamadoProvider>().carregarTodosChamados(),
      context.read<ObraProvider>().loadObras(),
      context.read<FilialProvider>().carregarFiliais(),
      context.read<ClienteProvider>().carregarClientes(),
      context.read<ServicoProvider>().carregarServicos(),
      context.read<EmployeeProvider>().loadAllEmployees(),
      ordemProvider.carregarTodasOrdens(),   // ← Adicionado aqui
    ]);
  }

  @override
  void initState() {
    super.initState();
    // Evita chamar durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filialProvider = context.watch<FilialProvider>();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal[700],
          title: const Text('Gestão de Chamados'),
          bottom: TabBar(
            onTap: (index) => setState(() => _currentTab = index),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            tabs: const [
              Tab(text: "Hoje"),
              Tab(text: "Semana"),
              Tab(text: "Técnicos"),
              Tab(text: "Obras"),
              Tab(text: "Pendentes"),
            ],
          ),
          actions: [
            // Seletor de Filial - Estilo transparente para combinar com AppBar
            SizedBox(
              width: 165,
              child: DropdownButtonFormField<String?>(
                value: _selectedFilialId,
                isDense: true,
                dropdownColor: Colors.teal[800],
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  filled: false,
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text("Todas as Filiais", style: TextStyle(color: Colors.white)),
                  ),
                  ...filialProvider.filiais.map((f) => DropdownMenuItem(
                    value: f.id,
                    child: Text(f.nome, style: const TextStyle(color: Colors.white)),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedFilialId = value),
              ),
            ),

            const SizedBox(width: 5), // ← Espaçamento de 5 pixels

            // Botão Adicionar
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChamadoFormScreen()),
              ).then((_) => _carregarDados()),
            ),
          ],
        ),
        body: Column(
          children: [
            const SummaryCards(),
            Expanded(
              child: TabBarView(
                children: [
                  TodayTab(onRefresh: _carregarDados, filialId: _selectedFilialId),
                  const WeekTab(),
                  ByTechnicianTab(onRefresh: _carregarDados, filialId: _selectedFilialId),
                  const ByObraTab(),
                  PendentesTab(onRefresh: _carregarDados, filialId: _selectedFilialId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}