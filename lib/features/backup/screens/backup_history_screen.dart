// lib/features/backup/screens/backup_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../obra/models/obra.dart';
import '../../obra/providers/obra_provider.dart';
import '../providers/backup_provider.dart';

class BackupHistoryScreen extends StatefulWidget {
  const BackupHistoryScreen({super.key});

  @override
  State<BackupHistoryScreen> createState() => _BackupHistoryScreenState();
}

class _BackupHistoryScreenState extends State<BackupHistoryScreen> {
  String _searchTerm = '';
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataSafely();
  }

  Future<void> _loadDataSafely() async {
    // Aguarda o frame atual terminar
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    setState(() => _isInitialLoading = true);

    try {
      await context.read<ObraProvider>().loadObras();
      if (!mounted) return;

      await context.read<BackupProvider>().listarTodosBackups();
    } catch (e) {
      debugPrint("Erro ao carregar backups: $e");
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupProvider = context.watch<BackupProvider>();
    final obraProvider = context.watch<ObraProvider>();

    final filteredBackups = backupProvider.allBackups.where((backup) {
      if (_searchTerm.isEmpty) return true;

      final data = backup['dados'] as Map<String, dynamic>? ?? {};
      final obraId = backup['obra_id'] as String?;

      final obra = obraProvider.obras.firstWhere(
            (o) => o.id == obraId,
        orElse: () => Obra(id: obraId ?? '', nome: 'Obra Excluída'),
      );

      final clienteNome = obraProvider.getClienteNome(obra.clienteId) ?? '';
      final texto = "${obra.nome} $clienteNome".toLowerCase();

      return texto.contains(_searchTerm.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico de Backups"),
        backgroundColor: Colors.teal[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDataSafely,
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar por obra ou cliente...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _searchTerm = value),
            ),
          ),

          Expanded(
            child: filteredBackups.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.backup, size: 100, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Nenhum backup encontrado"),
                  Text("Faça um backup manual primeiro", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredBackups.length,
              itemBuilder: (context, index) {
                final backup = filteredBackups[index];
                final data = backup['dados'] as Map<String, dynamic>? ?? {};
                final timestamp = DateTime.tryParse(data['timestamp'] ?? backup['created_at'] ?? '') ?? DateTime.now();
                final obraId = backup['obra_id'] as String?;

                final obra = obraProvider.obras.firstWhere(
                      (o) => o.id == obraId,
                  orElse: () => Obra(id: obraId ?? '', nome: 'Obra Excluída'),
                );

                final clienteNome = obraProvider.getClienteNome(obra.clienteId) ?? 'Cliente não encontrado';
                final totalAmbientes = data['total_ambientes'] ?? (data['ambientes'] as List?)?.length ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.backup, color: Colors.teal, size: 40),
                    title: Text(
                      "${obra.nome} — $clienteNome",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat("dd/MM/yyyy HH:mm").format(timestamp)),
                        Text("Tipo: ${backup['tipo']?.toUpperCase() ?? 'MANUAL'} • $totalAmbientes ambientes"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => _showBackupDetails(context, backup),
                        ),
                        IconButton(
                          icon: const Icon(Icons.restore, color: Colors.orange),
                          onPressed: () => _confirmarRestauracao(context, backup),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

  void _confirmarRestauracao(BuildContext context, Map<String, dynamic> backup) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("⚠️ Confirmar Restauração"),
        content: const Text(
          "Esta ação irá sobrescrever os dados atuais da obra.\n\n"
              "Tem certeza que deseja restaurar este backup?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!mounted) return;

              final backupProvider = context.read<BackupProvider>();
              final obraProvider = context.read<ObraProvider>();

              final success = await backupProvider.restaurarBackup(backup['id']);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Restauração concluída com sucesso!"),
                    backgroundColor: Colors.green,
                  ),
                );

                // Recarrega tudo
                await obraProvider.loadObras();
                await backupProvider.listarTodosBackups();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Falha na restauração"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Restaurar", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}