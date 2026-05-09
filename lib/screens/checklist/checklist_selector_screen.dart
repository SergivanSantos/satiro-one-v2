// lib/screens/checklist/checklist_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/checklist_provider.dart';
import 'checklist_execution_screen.dart';

class ChecklistSelectorScreen extends StatelessWidget {
  const ChecklistSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChecklistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha o Checklist para Executar'),
        backgroundColor: Colors.teal,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.checklists.isEmpty
          ? const Center(child: Text('Nenhum checklist criado ainda'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.checklists.length,
        itemBuilder: (context, index) {
          final checklist = provider.checklists[index];

          final totalGroups = checklist.groups.length;
          final totalItems = checklist.groups.fold<int>(
            0,
                (sum, group) => sum + group.subgroups.fold<int>(
              0,
                  (sum2, subgroup) => sum2 + subgroup.items.length,
            ),
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(checklist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$totalGroups grupos • $totalItems itens'),
              trailing: const Icon(Icons.play_arrow, color: Colors.teal),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChecklistExecutionScreen(
                      phaseConfigId: 0,           // modo teste
                      clientId: null,             // modo teste
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}