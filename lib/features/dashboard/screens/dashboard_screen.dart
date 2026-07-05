// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../obra/providers/obra_provider.dart';
import '../../obra/screens/obra_list_screen.dart';
import '../../obra/models/obra.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _todasFases = [];
  String? _selectedFilialId; // null = Todas

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObraProvider>().loadObras();
      _carregarTodasFases();
    });
  }

  Future<void> _carregarTodasFases() async {
    try {
      final res = await Supabase.instance.client
          .from('fase')
          .select('nome, ordem')
          .eq('ativo', true)
          .order('ordem', ascending: true);

      setState(() {
        _todasFases = List.from(res);
      });
    } catch (e) {
      debugPrint("Erro ao carregar fases: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraProvider>();

    // Filtra obras pela filial selecionada
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

    final Map<String, int> obrasPorFase = {};
    for (var obra in filteredObras) {
      final fase = obra.faseAtualNome ?? 'Sem Fase';
      obrasPorFase[fase] = (obrasPorFase[fase] ?? 0) + 1;
    }

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
              hint: const Text("Todas as Filiais", style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              dropdownColor: Colors.teal[800],
              style: const TextStyle(color: Colors.white),
              underline: Container(),
              items: [
                const DropdownMenuItem(value: null, child: Text("Todas as Filiais")),
                ...provider.filiaisUnicas.map((f) => DropdownMenuItem(
                  value: f['id'],
                  child: Text(f['nome'] ?? ''),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedFilialId = value);
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
            const Text("Visão Geral das Obras", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Atualizado agora • ${DateTime.now().hour.toString().padLeft(2,'0')}:${DateTime.now().minute.toString().padLeft(2,'0')}"),
            const SizedBox(height: 24),

            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCompactCard("Total", totalObras.toString(), Icons.home_work, Colors.teal, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ObraListScreen()));
                  }),
                  const SizedBox(width: 12),
                  _buildCompactCard("Andamento", emAndamento.toString(), Icons.play_circle_outline, Colors.blue, () {}),
                  const SizedBox(width: 12),
                  _buildCompactCard("Concluídas", concluidas.toString(), Icons.check_circle_outline, Colors.green, () {}),
                  const SizedBox(width: 12),
                  _buildCompactCard("Atrasadas", atrasadas.toString(), Icons.warning_amber, Colors.red, () {},
                      obras: filteredObras.where((o) => o.statusCronograma.contains("Atrasado")).toList(), provider: provider),
                  const SizedBox(width: 12),
                  _buildCompactCard("Próximas a Vencer", proximasVencer.toString(), Icons.timer, Colors.orange, () {},
                      obras: filteredObras.where((o) {
                        if (o.dataFimPrevistaFase == null) return false;
                        final dias = o.dataFimPrevistaFase!.difference(DateTime.now()).inDays;
                        return dias >= 0 && dias <= 15;
                      }).toList(), provider: provider),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text("Obras por Fase", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 480,
              child: _buildBarChart(obrasPorFase),
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
            TextSpan(text: "$title:\n", style: const TextStyle(fontWeight: FontWeight.bold)),
            ...obras.take(8).map((obra) => TextSpan(
              text: "• ${obra.nome} - ${provider?.getClienteNome(obra.clienteId) ?? 'Sem cliente'}\n",
              style: const TextStyle(fontSize: 13),
            )),
            if (obras.length > 8) TextSpan(text: "... e mais ${obras.length - 8}"),
          ],
        ),
        preferBelow: false,
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
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
                    Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> obrasPorFase) {
    final List<BarChartGroupData> barGroups = [];
    final List<Color> colors = [
      Colors.teal[700]!, Colors.blue[700]!, Colors.green[700]!,
      Colors.orange[700]!, Colors.purple[700]!, Colors.indigo[700]!,
      Colors.pink[700]!, Colors.cyan[700]!
    ];

    for (int i = 0; i < _todasFases.length; i++) {
      final faseNome = _todasFases[i]['nome'] as String;
      final count = obrasPorFase[faseNome] ?? 0;
      final color = colors[i % colors.length];

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: color,
              width: 32,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ],
          showingTooltipIndicators: count > 0 ? [0] : [], // Força o tooltip a aparecer
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: obrasPorFase.values.isEmpty ? 10 : obrasPorFase.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.3,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final fase = _todasFases[group.x]['nome'] as String;
              return BarTooltipItem(
                '$fase\n',
                const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: rod.toY.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _todasFases.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: Text(
                        _todasFases[value.toInt()]['nome'] as String,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 140,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 0.1,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFFE0E0E0),
            strokeWidth: 2,
          ),
          getDrawingVerticalLine: (value) => const FlLine(
            color: Color(0xFFE0E0E0),
            strokeWidth: 2,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        groupsSpace: 1,
      ),
    );
  }
}