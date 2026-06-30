// lib/features/os/screens/os_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../obra/models/obra.dart';
import '../models/ordem_servico.dart';
import '../providers/os_provider.dart';
import '../../obra/providers/obra_provider.dart';

class OsDetailScreen extends StatelessWidget {
  final OrdemServico ordem;

  const OsDetailScreen({super.key, required this.ordem});

  @override
  Widget build(BuildContext context) {
    final osProvider = context.watch<OsProvider>();
    final obraProvider = context.watch<ObraProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ordem de Serviço"),
        backgroundColor: Colors.teal[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Obra: ${obraProvider.obras.firstWhere((o) => o.id == ordem.obraId, orElse: () => Obra(id: '', nome: 'Não encontrada')).nome}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Data: ${DateFormat("dd/MM/yyyy").format(ordem.data)}"),
                    Text("Status: ${ordem.status.toUpperCase()}"),
                    if (ordem.checkIn != null) Text("Check-in: ${DateFormat("HH:mm").format(ordem.checkIn!)}"),
                    if (ordem.checkOut != null) Text("Check-out: ${DateFormat("HH:mm").format(ordem.checkOut!)}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text("Serviços", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Aqui virá a lista de itens da ordem (futuramente)
            const Center(child: Text("Lista de serviços em desenvolvimento")),
          ],
        ),
      ),
    );
  }
}