// lib/features/obra/screens/obra_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/obra_provider.dart';
import '../models/obra.dart';
import 'obra_form_screen.dart';
import 'obra_detail_screen.dart';   // ← Nova importação

class ObraListScreen extends StatefulWidget {
  const ObraListScreen({super.key});

  @override
  State<ObraListScreen> createState() => _ObraListScreenState();
}

class _ObraListScreenState extends State<ObraListScreen> {
  String _filtroStatus = 'Todas';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObraProvider>().loadObras();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraProvider>();
    final obrasFiltradas = _filtroStatus == 'Todas'
        ? provider.obras
        : provider.obras.where((o) => o.status == _filtroStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Obras'),
        backgroundColor: Colors.teal[800],
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filtroStatus = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Todas', child: Text('Todas as Obras')),
              const PopupMenuItem(value: 'em_andamento', child: Text('Em Andamento')),
              const PopupMenuItem(value: 'pausada', child: Text('Pausadas')),
              const PopupMenuItem(value: 'concluida', child: Text('Concluídas')),
            ],
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : obrasFiltradas.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 90, color: Colors.grey),
            SizedBox(height: 20),
            Text('Nenhuma obra encontrada', style: TextStyle(fontSize: 20)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: obrasFiltradas.length,
        itemBuilder: (context, index) {
          final obra = obrasFiltradas[index];
          final colorStatus = obra.status == 'concluida'
              ? Colors.green
              : obra.status == 'pausada'
              ? Colors.orange
              : Colors.blue;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ObraDetailScreen(obra: obra),
                ),
              );
            },
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.home_work, color: colorStatus, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            obra.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Chip(
                          label: Text(obra.status.toUpperCase()),
                          backgroundColor: colorStatus.withOpacity(0.2),
                          labelStyle: TextStyle(color: colorStatus, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (obra.address != null)
                      Text('📍 ${obra.address!}', style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (obra.dataInicio != null)
                          Text('Início: ${DateFormat('dd/MM/yyyy').format(obra.dataInicio!)}'),
                        const Spacer(),
                        if (obra.dataPrevistaFim != null)
                          Text('Previsão: ${DateFormat('dd/MM/yyyy').format(obra.dataPrevistaFim!)}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (obra.valorOrcado > 0)
                      Text(
                        'Valor Orçado: R\$ ${obra.valorOrcado.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    if (obra.observacoes != null && obra.observacoes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(obra.observacoes!, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ObraFormScreen()),
          );
          if (result == true) {
            provider.loadObras(); // Atualiza lista
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Obra'),
        backgroundColor: Colors.teal,
      ),
    );
  }
}