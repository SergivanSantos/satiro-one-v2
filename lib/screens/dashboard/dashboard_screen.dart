// lib/checklist/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/brand.dart';
import '../../models/employee.dart';
import '../../models/client.dart';
import '../../providers/brand_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/birthday_message_provider.dart';
import '../../screens/anniversaries/anniversaries_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _sendWhatsAppBirthday(BuildContext context, String? whatsapp, String name) async {
    if (whatsapp == null || whatsapp.trim().isEmpty) return;

    final provider = Provider.of<BirthdayMessageProvider>(context, listen: false);
    final template = provider.birthdayMessage;
    final message = Uri.encodeComponent(template.replaceAll('{nome}', name));
    final url = Uri.parse('https://wa.me/55$whatsapp?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
      );
    }
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
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = now.month;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TÍTULO PRINCIPAL
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          Text(
            DateFormat('dd MMMM yyyy', 'pt_BR').format(now),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
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


                  Consumer2<EmployeeProvider, ClientProvider>(
                    builder: (context, employeeProvider, clientProvider, _) {
                      // Funcionários com aniversário este mês
                      final aniversariantesFuncionarios = employeeProvider.employees
                          .where((e) => e.birthDate != null && e.birthDate!.month == currentMonth)
                          .toList()
                        ..sort((a, b) => a.birthDate!.day.compareTo(b.birthDate!.day));

                      // Clientes com aniversário este mês
                      final aniversariantesClientes = clientProvider.clients
                          .where((c) => c.birthDate != null && c.birthDate!.month == currentMonth)
                          .toList()
                        ..sort((a, b) => a.birthDate!.day.compareTo(b.birthDate!.day));

                      final totalAniversariantes = aniversariantesFuncionarios.length + aniversariantesClientes.length;

                      return Column(
                        children: [
                          if (totalAniversariantes == 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'Nenhum aniversariante este mês 🎂',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            )
                          else ...[
                            Text(
                              '$totalAniversariantes aniversariantes este mês',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.purple),
                            ),
                            const SizedBox(height: 16),
                          ],

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Coluna esquerda: Funcionários
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Funcionários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    if (aniversariantesFuncionarios.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 20),
                                        child: Text('Nenhum neste mês', style: TextStyle(color: Colors.grey)),
                                      )
                                    else
                                      ...aniversariantesFuncionarios.take(10).map((e) => ListTile(
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
                                        title: Text(e.name, style: const TextStyle(fontSize: 14)),
                                        subtitle: Text(DateFormat('dd/MM').format(e.birthDate!)),
                                        trailing: e.whatsapp != null
                                            ? IconButton(
                                          icon: const Icon(Icons.message_rounded, color: Colors.green, size: 20),
                                          onPressed: () => _sendWhatsAppBirthday(context, e.whatsapp, e.name),
                                        )
                                            : null,
                                      )),
                                    if (aniversariantesFuncionarios.length > 10)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const AniversariesScreen()),
                                          ),
                                          child: const Text('Ver todos →'),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 32),

                              // Coluna direita: Clientes
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Clientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    if (aniversariantesClientes.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 20),
                                        child: Text('Nenhum neste mês', style: TextStyle(color: Colors.grey)),
                                      )
                                    else
                                      ...aniversariantesClientes.take(10).map((c) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          radius: 18,
                                          child: Text(c.name[0].toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        ),
                                        title: Text(c.name, style: const TextStyle(fontSize: 14)),
                                        subtitle: Text(DateFormat('dd/MM').format(c.birthDate!)),
                                        trailing: c.phone != null
                                            ? IconButton(
                                          icon: const Icon(Icons.message_rounded, color: Colors.green, size: 20),
                                          onPressed: () => _sendWhatsAppBirthday(context, c.phone, c.name),
                                        )
                                            : null,
                                      )),
                                    if (aniversariantesClientes.length > 10)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Ver todos os clientes em breve')),
                                            );
                                          },
                                          child: const Text('Ver todos →'),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
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

          // CARD: MOVIMENTAÇÕES RECENTES + RESUMO DE FUNCIONÁRIOS
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

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MOVIMENTAÇÕES RECENTES
                  Expanded(
                    child: Card(
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
                                Icon(Icons.event_busy_rounded, color: Colors.orange, size: 36),
                                SizedBox(width: 12),
                                Text('Movimentações Recentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                final DateTime? date = isDesligado ? e.dataSaida : e.dataInicioAfastamento;
                                final String motivo = isDesligado ? (e.motivoSaida ?? 'Desligamento') : (e.statusAfastamento ?? 'Afastamento');

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    isDesligado ? Icons.person_off_rounded : Icons.event_busy_rounded,
                                    color: isDesligado ? Colors.red : Colors.orange,
                                    size: 32,
                                  ),
                                  title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(motivo),
                                      if (date != null) Text(DateFormat('dd/MM/yyyy').format(date)),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // RESUMO DE FUNCIONÁRIOS
                  Expanded(
                    child: Card(
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
                                Icon(Icons.people_alt_rounded, color: Colors.teal, size: 36),
                                SizedBox(width: 12),
                                Text('Resumo de Funcionários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}