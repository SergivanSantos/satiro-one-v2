// lib/features/backup/screens/obra_backup_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // ← Adicionado para JsonEncoder

import '../../obra/models/obra.dart';
import '../providers/backup_provider.dart';

class ObraBackupHistoryScreen extends StatefulWidget {
  final Obra obra;

  const ObraBackupHistoryScreen({super.key, required this.obra});

  @override
  State<ObraBackupHistoryScreen> createState() => _ObraBackupHistoryScreenState();
}

class _ObraBackupHistoryScreenState extends State<ObraBackupHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackupProvider>().listarBackups(widget.obra.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final backupProvider = context.watch<BackupProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Backups - ${widget.obra.nome}"),
        backgroundColor: Colors.teal[900],
      ),
      body: backupProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : backupProvider.backups.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.backup, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text("Nenhum backup encontrado", style: TextStyle(fontSize: 18)),
            Text("Faça o primeiro backup manual", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: backupProvider.backups.length,
        itemBuilder: (context, index) {
          final backup = backupProvider.backups[index];
          final data = backup['dados'] as Map<String, dynamic>? ?? {};
          final timestamp = DateTime.tryParse(data['timestamp'] ?? backup['created_at'] ?? '') ?? DateTime.now();
          final totalAmbientes = data['total_ambientes'] ?? (data['ambientes'] as List?)?.length ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.backup, color: Colors.teal, size: 40),
              title: Text(
                DateFormat("dd/MM/yyyy HH:mm").format(timestamp),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tipo: ${backup['tipo']?.toUpperCase() ?? 'MANUAL'}"),
                  Text("Ambientes: $totalAmbientes"),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                onPressed: () => _showBackupDetails(context, backup),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final success = await context.read<BackupProvider>().fazerBackupObra(widget.obra.id);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Novo backup criado!"), backgroundColor: Colors.green),
            );
            context.read<BackupProvider>().listarBackups(widget.obra.id);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showBackupDetails(BuildContext context, Map<String, dynamic> backup) {
    final data = backup['dados'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Detalhes do Backup"),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: SingleChildScrollView(
            child: Text(
              const JsonEncoder.withIndent('  ').convert(data),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
  }
}