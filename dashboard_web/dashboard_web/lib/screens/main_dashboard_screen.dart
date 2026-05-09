// lib/checklist/main_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/employee.dart';
import '../../providers/employee_provider.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendWhatsAppBirthday(String? whatsapp, String name) async {
    if (whatsapp == null || whatsapp.trim().isEmpty) return;

    final cleaned = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
        'Parabéns pelo seu aniversário, $name! \nDesejamos saúde, sucesso e muitas realizações!\nEquipe Satiro One');
    final url = Uri.parse('https://wa.me/55$cleaned?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Satiro One',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          Text(
            DateFormat('dd MMMM yyyy', 'pt_BR').format(now),
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 30),

          // CARD: ANIVERSARIANTES DO MÊS
          Card(
            elevation: 6,
            color: Colors.purple[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Aniversariantes do Mês',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Consumer<EmployeeProvider>(
                    builder: (context, provider, _) {
                      final aniversariantesFuncionarios = provider.employees
                          .where((e) => e.birthDate != null && e.birthDate!.month == now.month)
                          .toList()
                        ..sort((a, b) => a.birthDate!.day.compareTo(b.birthDate!.day));

                      return isMobile
                          ? Column(
                        children: [
                          const Text(
                            'Funcionários',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), // CORRIGIDO
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildBirthdayList(aniversariantesFuncionarios, now),
                          const SizedBox(height: 30),
                          const Text(
                            'Clientes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), // CORRIGIDO
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'Em breve...',
                                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                          : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Funcionários',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), // CORRIGIDO
                                ),
                                const Divider(),
                                const SizedBox(height: 8),
                                _buildBirthdayList(aniversariantesFuncionarios, now),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Clientes',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), // CORRIGIDO
                                ),
                                const Divider(),
                                const SizedBox(height: 8),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 60),
                                  child: Center(
                                    child: Text(
                                      'Em breve...',
                                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          Consumer<EmployeeProvider>(
            builder: (context, provider, _) {
              final employees = provider.employees;

              final total = employees.length;
              final ativos = employees.where((e) => e.isActive && (e.statusAfastamento == null || e.statusAfastamento!.isEmpty)).length;
              final afastados = employees.where((e) => e.statusAfastamento != null && e.statusAfastamento!.isNotEmpty && e.isActive).length;
              final desligados = employees.where((e) => !e.isActive).length;

              final movimentacoes = employees.where((e) {
                return !e.isActive || (e.statusAfastamento != null && e.statusAfastamento!.isNotEmpty);
              }).toList()
                ..sort((a, b) {
                  final dateA = a.dataInicioAfastamento ?? a.dataSaida ?? DateTime(1900);
                  final dateB = b.dataInicioAfastamento ?? b.dataSaida ?? DateTime(1900);
                  return dateB.compareTo(dateA);
                });

              return isMobile
                  ? Column(
                children: [
                  _buildMovimentacoesCard(movimentacoes),
                  const SizedBox(height: 30),
                  _buildResumoCard(total, ativos, afastados, desligados),
                ],
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMovimentacoesCard(movimentacoes)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildResumoCard(total, ativos, afastados, desligados)),
                ],
              );
            },
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBirthdayList(List<Employee> aniversariantes, DateTime now) {
    if (aniversariantes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Nenhum neste mês', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: aniversariantes.take(10).map((e) {
        final bool isToday = e.birthDate != null &&
            e.birthDate!.day == now.day &&
            e.birthDate!.month == now.month;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isToday ? Colors.yellow.withOpacity(0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isToday ? Border.all(color: Colors.orangeAccent, width: 2) : null,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 18,
              backgroundImage: e.photoPath != null && e.photoPath!.startsWith('http')
                  ? NetworkImage(e.photoPath!)
                  : null,
              child: e.photoPath == null || !e.photoPath!.startsWith('http')
                  ? Text(e.name[0].toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(e.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                if (isToday)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(' HOJE!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                        SizedBox(width: 8),
                        Text('🎂', style: TextStyle(fontSize: 22)),
                        Text('🎉', style: TextStyle(fontSize: 22)),
                        Text('🎊', style: TextStyle(fontSize: 22)),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Text(DateFormat('dd/MM').format(e.birthDate!)),
            trailing: e.whatsapp != null
                ? IconButton(
              icon: const Text('💬', style: TextStyle(fontSize: 22)),
              onPressed: () => _sendWhatsAppBirthday(e.whatsapp, e.name),
            )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMovimentacoesCard(List<Employee> movimentacoes) {
    return Card(
      elevation: 6,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('⚠️', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Text('Movimentações Recentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // CORRIGIDO
              ],
            ),
            const SizedBox(height: 16),
            if (movimentacoes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Nenhuma movimentação recente', style: TextStyle(color: Colors.grey)),
              )
            else
              ...movimentacoes.take(8).map((e) {
                final bool isDesligado = !e.isActive;
                final String emoji = isDesligado ? '❌' : '⚠️';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(emoji, style: TextStyle(fontSize: 28)),
                  title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isDesligado
                          ? (e.motivoSaida ?? 'Desligamento')
                          : (e.statusAfastamento ?? 'Afastamento')),
                      if (e.dataSaida != null || e.dataInicioAfastamento != null)
                        Text(DateFormat('dd/MM/yyyy').format(isDesligado ? e.dataSaida! : e.dataInicioAfastamento!), style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCard(int total, int ativos, int afastados, int desligados) {
    return Card(
      elevation: 6,
      color: Colors.teal[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('👥', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Text('Resumo de Funcionários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // CORRIGIDO
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _buildCompactStat('Total', total.toString(), Colors.teal),
                _buildCompactStat('Ativos', ativos.toString(), Colors.green),
                _buildCompactStat('Afastados', afastados.toString(), Colors.orange),
                _buildCompactStat('Desligados', desligados.toString(), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87), // CORRIGIDO para melhor contraste
        ),
      ],
    );
  }
}