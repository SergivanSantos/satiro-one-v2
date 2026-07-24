// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../obra/providers/obra_provider.dart';
import '../../obra/screens/obra_list_screen.dart';
import '../../obra/models/obra.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedFilialId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ObraProvider>().loadObras();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraProvider>();

    final filteredObras = _selectedFilialId == null
        ? provider.obras
        : provider.obras.where((o) => o.filialId == _selectedFilialId).toList();

    final totalObras = filteredObras.length;
    final emAndamento = filteredObras.where((o) => o.status == 'em_andamento').length;
    final concluidas = filteredObras.where((o) => o.status == 'concluida').length;
    final atrasadas = filteredObras.where((o) => o.statusCronograma.contains("Atrasado")).length;

    final proximasVencer = filteredObras.where((o) {
      if (o.dataFimPrevistaFase == null) return false;
      final dias = o.dataFimPrevistaFase!.difference(DateTime.now()).inDays;
      return dias >= 0 && dias <= 15;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<String?>(
              value: _selectedFilialId,
              hint: const Text(
                "Todas as Filiais",
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              dropdownColor: Colors.teal[800],
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text("Todas as Filiais"),
                ),
                // Só adiciona itens que tenham id válido
                ...provider.filiaisUnicas
                    .where((f) => f['id'] != null && f['id'].toString().isNotEmpty)
                    .map((f) {
                  final id = f['id'].toString();
                  final nome = f['nome']?.toString() ?? 'Sem nome';
                  return DropdownMenuItem<String?>(
                    value: id,
                    child: Text(nome),
                  );
                }),
              ],
              onChanged: (value) {
                if (mounted) {
                  setState(() => _selectedFilialId = value);
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Visão Geral das Obras",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Atualizado agora • ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),

            // ===================== CARDS DE RESUMO =====================
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCompactCard(
                    "Total",
                    totalObras.toString(),
                    Icons.home_work,
                    Colors.teal,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ObraListScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildCompactCard(
                    "Andamento",
                    emAndamento.toString(),
                    Icons.play_circle_outline,
                    Colors.blue,
                        () {},
                  ),
                  const SizedBox(width: 12),
                  _buildCompactCard(
                    "Concluídas",
                    concluidas.toString(),
                    Icons.check_circle_outline,
                    Colors.green,
                        () {},
                  ),
                  const SizedBox(width: 12),
                  _buildCompactCard(
                    "Atrasadas",
                    atrasadas.toString(),
                    Icons.warning_amber,
                    Colors.red,
                        () {},
                    obras: filteredObras
                        .where((o) => o.statusCronograma.contains("Atrasado"))
                        .toList(),
                    provider: provider,
                  ),
                  const SizedBox(width: 12),
                  _buildCompactCard(
                    "Próximas a Vencer",
                    proximasVencer.toString(),
                    Icons.timer,
                    Colors.orange,
                        () {},
                    obras: filteredObras.where((o) {
                      if (o.dataFimPrevistaFase == null) return false;
                      final dias = o.dataFimPrevistaFase!.difference(DateTime.now()).inDays;
                      return dias >= 0 && dias <= 15;
                    }).toList(),
                    provider: provider,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Espaço reservado para futuros indicadores importantes
            // (ex: materiais pendentes, chamados abertos, faturamento, etc.)
            Center(
              child: Text(
                "Em breve: indicadores de andamento real das obras",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(
      String title,
      String value,
      IconData icon,
      Color color,
      VoidCallback onTap, {
        List<Obra> obras = const [],
        ObraProvider? provider,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        richMessage: obras.isEmpty
            ? TextSpan(text: title)
            : TextSpan(
          children: [
            TextSpan(
              text: "$title:\n",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...obras.take(8).map((obra) => TextSpan(
              text:
              "• ${obra.nome} - ${provider?.getClienteNome(obra.clienteId) ?? 'Sem cliente'}\n",
              style: const TextStyle(fontSize: 13),
            )),
            if (obras.length > 8)
              TextSpan(text: "... e mais ${obras.length - 8}"),
          ],
        ),
        preferBelow: false,
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 42),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}