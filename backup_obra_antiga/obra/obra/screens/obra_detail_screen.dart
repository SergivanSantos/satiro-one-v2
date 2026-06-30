// lib/features/obra/screens/obra_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/obra.dart';
import '../providers/obra_estrutura_provider.dart';
import 'chamados_list_screen.dart';
import 'obra_builder_screen.dart';
import 'obra_visual_matrix_screen.dart';

class ObraDetailScreen extends StatefulWidget {
  final Obra obra;
  const ObraDetailScreen({super.key, required this.obra});

  @override
  State<ObraDetailScreen> createState() => _ObraDetailScreenState();
}

class _ObraDetailScreenState extends State<ObraDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMatrixView = false; // Controle para alternar entre Construtor e Matriz

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObraEstruturaProvider>().loadEstrutura(widget.obra.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obra = widget.obra;

    return Scaffold(
      appBar: AppBar(
        title: Text(obra.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
        actions: [
          // Botão de Chamados
          IconButton(
            icon: const Icon(Icons.assignment_turned_in),
            tooltip: 'Chamados',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChamadosListScreen(
                    obraId: widget.obra.id,
                    obraNome: widget.obra.name,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange[400],
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.account_tree), text: 'Estrutura'),
            Tab(icon: Icon(Icons.attach_money), text: 'Gastos'),
            Tab(icon: Icon(Icons.pending), text: 'Pendências'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const Center(child: Text('Dashboard em desenvolvimento')),

          // ==================== ABA ESTRUTURA ====================
          Column(
            children: [
              // Barra de alternância entre Construtor e Matriz
              Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Construtor'),
                      selected: !_isMatrixView,
                      onSelected: (selected) {
                        setState(() => _isMatrixView = false);
                      },
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Visão Matriz'),
                      selected: _isMatrixView,
                      onSelected: (selected) {
                        setState(() => _isMatrixView = true);
                      },
                    ),
                  ],
                ),
              ),

              // Conteúdo dinâmico
              Expanded(
                child: _isMatrixView
                    ? ObraVisualMatrixScreen(
                  obraId: widget.obra.id,
                  obraNome: widget.obra.name,
                )
                    : ObraBuilderScreen(
                  obraId: widget.obra.id,
                  obraNome: widget.obra.name,
                ),
              ),
            ],
          ),

          const Center(child: Text('Módulo de Gastos\n(Em desenvolvimento)')),
          const Center(child: Text('Módulo de Pendências\n(Em desenvolvimento)')),
        ],
      ),
    );
  }
}