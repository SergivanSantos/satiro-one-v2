// lib/features/client/screens/cliente_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cliente.dart';
import '../providers/cliente_provider.dart';
import '../../obra/providers/obra_provider.dart';
import '../../obra/screens/obras_por_cliente_screen.dart';
import 'cliente_form_screen.dart';

class ClienteDetailScreen extends StatelessWidget {
  final Cliente cliente;

  const ClienteDetailScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final clienteProvider = context.watch<ClienteProvider>();
    final obraProvider = context.watch<ObraProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes do Cliente"),
        backgroundColor: Colors.teal[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClienteFormScreen(cliente: cliente),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal[100],
                    child: const Icon(Icons.person, size: 60, color: Colors.teal),
                  ),
                  const SizedBox(height: 16),
                  Text(cliente.nome, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(cliente.cpfCnpj ?? 'Sem CPF/CNPJ', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Informações", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _infoRow("Telefone", cliente.telefone ?? 'Não informado'),
                    _infoRow("Email", cliente.email ?? 'Não informado'),
                    _infoRow("Endereço", cliente.endereco ?? 'Não informado'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.home_work, color: Colors.white),
              label: const Text("Ver Obras deste Cliente"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(280, 52),   // Largura menor
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ObrasPorClienteScreen(cliente: cliente),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}