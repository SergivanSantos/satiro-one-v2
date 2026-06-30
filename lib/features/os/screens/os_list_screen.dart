// lib/features/os/screens/os_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/os_provider.dart';
import '../models/ordem_servico.dart';
import 'os_form_screen.dart';
import 'os_detail_screen.dart';

class OsListScreen extends StatefulWidget {
  const OsListScreen({super.key});

  @override
  State<OsListScreen> createState() => _OsListScreenState();
}

class _OsListScreenState extends State<OsListScreen> {
  DateTime _dataSelecionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OsProvider>().loadOrdens(data: _dataSelecionada);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ordens de Serviço"),
        backgroundColor: Colors.teal[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dataSelecionada,
                firstDate: DateTime(2025),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) {
                setState(() => _dataSelecionada = date);
                provider.loadOrdens(data: date);
              }
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.ordens.isEmpty
          ? const Center(child: Text("Nenhuma ordem de serviço encontrada"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.ordens.length,
        itemBuilder: (context, index) {
          final os = provider.ordens[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.assignment, color: Colors.teal, size: 40),
              title: Text(
                os.obraNome ?? 'Obra não informada',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Fase: ${os.faseNome ?? 'Geral'}"),
                  Text("Técnico: ${os.tecnicoNome ?? 'Não atribuído'}"),
                  Text("Data: ${DateFormat("dd/MM/yyyy").format(os.data)}"),
                ],
              ),
              trailing: Chip(
                label: Text(os.status.toUpperCase()),
                backgroundColor: _getStatusColor(os.status),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OsDetailScreen(ordem: os),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OsFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Nova Ordem"),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'concluida':
        return Colors.green[100]!;
      case 'em_andamento':
        return Colors.orange[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}