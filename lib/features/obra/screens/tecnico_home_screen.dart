// lib/features/obra/screens/tecnico_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../rh/providers/employee_provider.dart';
import '../providers/ordem_servico_provider.dart';
import 'ordem_servico_atendimento_screen.dart';

class TecnicoHomeScreen extends StatefulWidget {
  const TecnicoHomeScreen({super.key});

  @override
  State<TecnicoHomeScreen> createState() => _TecnicoHomeScreenState();
}

class _TecnicoHomeScreenState extends State<TecnicoHomeScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdemServicoProvider>().carregarOrdensDoTecnico(); // Método que vamos criar
    });
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final ordemProvider = context.watch<OrdemServicoProvider>();

    final tecnicoNome = employeeProvider.currentEmployee?.name?.split(' ').first ?? 'Técnico';
    final ordensDoTecnico = ordemProvider.ordens; // Filtrar por técnico logado

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Técnico'),
        backgroundColor: Colors.orange[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ordemProvider.carregarOrdensDoTecnico(),
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
        onRefresh: () => ordemProvider.carregarOrdensDoTecnico(),
        child: ordensDoTecnico.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.engineering_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhum chamado alocado no momento', style: TextStyle(fontSize: 18)),
              Text('Quando houver ordens atribuídas a você, elas aparecerão aqui.',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: ordensDoTecnico.length,
          itemBuilder: (context, index) {
            final ordem = ordensDoTecnico[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(ordem.status),
                  child: const Icon(Icons.assignment, color: Colors.white),
                ),
                title: Text(ordem.titulo ?? 'Sem título', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Obra: ${ordem.obraNome ?? '—'}"),
                    Text("Fase: ${ordem.faseNome ?? '—'}"),
                    if (ordem.dataInicioPrevista != null)
                      Text("Início previsto: ${_dateFormat.format(ordem.dataInicioPrevista!)}"),
                  ],
                ),
                trailing: Chip(
                  label: Text(ordem.status.toUpperCase()),
                  backgroundColor: _getStatusColor(ordem.status).withOpacity(0.15),
                  labelStyle: TextStyle(color: _getStatusColor(ordem.status)),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrdemServicoAtendimentoScreen(ordem: ordem),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'concluida': return Colors.green;
      case 'em_andamento': return Colors.orange;
      default: return Colors.blue;
    }
  }
}