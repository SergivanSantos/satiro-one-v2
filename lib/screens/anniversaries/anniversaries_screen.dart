// lib/checklist/anniversaries/anniversaries_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/employee.dart';
import '../../providers/employee_provider.dart';

class AniversariesScreen extends StatelessWidget {
  const AniversariesScreen({super.key});

  Future<void> _sendWhatsAppBirthday(String? whatsapp, String name) async {
    if (whatsapp == null || whatsapp.trim().isEmpty) {
      return;
    }

    final cleaned = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent('Parabéns pelo seu aniversário, $name! 🎉\n'
        'Desejamos tudo de melhor, saúde, sucesso e muitas conquistas!\n'
        'Equipe Satiro One');

    final url = Uri.parse('https://wa.me/55$cleaned?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = now.month;

    return Scaffold(
      appBar: AppBar(
        title: Text('Aniversariantes de ${DateFormat('MMMM').format(now).toUpperCase()} 🎂'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final aniversariantes = provider.employees.where((employee) {
            if (employee.birthDate == null) return false;
            return employee.birthDate!.month == currentMonth;
          }).toList();

          // Ordena por dia do aniversário
          aniversariantes.sort((a, b) => a.birthDate!.day.compareTo(b.birthDate!.day));

          if (aniversariantes.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum funcionário faz aniversário neste mês.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: aniversariantes.length,
            itemBuilder: (context, index) {
              final employee = aniversariantes[index];
              final day = employee.birthDate!.day;
              final formattedDate = DateFormat('dd/MM').format(employee.birthDate!);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: employee.photoPath != null && File(employee.photoPath!).existsSync()
                        ? FileImage(File(employee.photoPath!))
                        : null,
                    child: employee.photoPath == null || !File(employee.photoPath!).existsSync()
                        ? Text(
                      employee.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    )
                        : null,
                  ),
                  title: Text(
                    employee.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cargo: ${employee.role ?? 'Não informado'}'),
                      Text('Aniversário: $formattedDate'),
                      if (employee.isActive == false)
                        const Text('Desligado', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: employee.whatsapp != null
                      ? IconButton(
                    icon: const Icon(Icons.message, color: Colors.green, size: 30),
                    tooltip: 'Parabenizar no WhatsApp',
                    onPressed: () => _sendWhatsAppBirthday(employee.whatsapp, employee.name),
                  )
                      : const Icon(Icons.phone_disabled, color: Colors.grey),
                  onTap: () => _sendWhatsAppBirthday(employee.whatsapp, employee.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}