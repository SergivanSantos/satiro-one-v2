// lib/features/obra/screens/obra_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/obra.dart';
import '../providers/obra_estrutura_provider.dart';   // Novo provider hierárquico

class ObraDashboardScreen extends StatefulWidget {
  final Obra obra;
  const ObraDashboardScreen({super.key, required this.obra});

  @override
  State<ObraDashboardScreen> createState() => _ObraDashboardScreenState();
}

class _ObraDashboardScreenState extends State<ObraDashboardScreen> {
  final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    context.read<ObraEstruturaProvider>().loadEstrutura(widget.obra.id);
  }

  @override
  Widget build(BuildContext context) {
    final estruturaProvider = context.watch<ObraEstruturaProvider>();

    final totalUnidades = estruturaProvider.blocos
        .expand((bloco) => []) // Aqui vamos expandir quando tivermos pisos/unidades
        .length; // Temporário

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${widget.obra.name}'),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progresso Geral
            Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Progresso Geral da Obra',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: 0.52,
                      minHeight: 22,
                      color: Colors.teal,
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    const Text('52% Concluído',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Cards de Resumo
            Row(
              children: [
                Expanded(
                  child: _resumoCard(
                    'Blocos',
                    estruturaProvider.blocos.length.toString(),
                    Icons.apartment,
                  ),
                ),
                Expanded(
                  child: _resumoCard(
                    'Valor Orçado',
                    formatter.format(widget.obra.valorOrcado ?? 0),
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Estrutura Resumida
            const Text('Estrutura da Obra', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (estruturaProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (estruturaProvider.blocos.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Nenhum bloco cadastrado ainda'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: estruturaProvider.blocos.length,
                itemBuilder: (context, index) {
                  final bloco = estruturaProvider.blocos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.apartment, color: Colors.teal, size: 40),
                      title: Text(bloco.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Clique para ver pisos e unidades'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Futuramente abrir tela detalhada do bloco
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Abrindo ${bloco.nome}')),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _resumoCard(String titulo, String valor, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Colors.teal),
            const SizedBox(height: 8),
            Text(titulo, style: const TextStyle(fontSize: 14)),
            Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}