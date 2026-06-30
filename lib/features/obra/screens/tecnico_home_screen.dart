// lib/features/obra/screens/tecnico_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../rh/providers/employee_provider.dart';

class TecnicoHomeScreen extends StatefulWidget {
  const TecnicoHomeScreen({super.key});

  @override
  State<TecnicoHomeScreen> createState() => _TecnicoHomeScreenState();
}

class _TecnicoHomeScreenState extends State<TecnicoHomeScreen> {
  final Map<String, bool> _expandedClients = {};

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final tecnicoNome = employeeProvider.currentEmployee?.name?.split(' ').first ?? 'Técnico';

    // Dados simulados (substitua depois pelos providers reais)
    final List<Map<String, dynamic>> clientesSimulados = [
      {
        'id': '1',
        'nome': 'Rafael Moura',
        'obra': 'Casa 1 - Solar',
        'chamados': 2,
        'pendencias': 1,
        'descricao': 'Vazamento na cozinha e tomada queimada',
      },
      {
        'id': '2',
        'nome': 'Maria Silva',
        'obra': 'Sobrado 2',
        'chamados': 1,
        'pendencias': 2,
        'descricao': 'Problemas elétricos na área externa',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Técnico'),
        backgroundColor: Colors.orange[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Atualizando dados...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await employeeProvider.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Futuro: recarregar dados
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Olá, $tecnicoNome!',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (clientesSimulados.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.engineering_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Nenhum chamado alocado no momento', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final cliente = clientesSimulados[index];
                    final clientId = cliente['id'];
                    final isExpanded = _expandedClients[clientId] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () {
                          setState(() => _expandedClients[clientId] = !isExpanded);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.teal,
                                    child: Text(
                                      cliente['nome'][0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(cliente['nome'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        Text('Obra: ${cliente['obra']}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${cliente['chamados']} chamados', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('${cliente['pendencias']} pendências', style: TextStyle(color: Colors.orange[700])),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            if (isExpanded) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Descrição: ${cliente['descricao']}", style: const TextStyle(fontSize: 14)),
                                    const SizedBox(height: 12),
                                    const Text("Pendências pendentes:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    const Text("• Vazamento na cozinha", style: TextStyle(color: Colors.red)),
                                    const Text("• Tomada queimada", style: TextStyle(color: Colors.orange)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: clientesSimulados.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}