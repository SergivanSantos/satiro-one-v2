import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/checklist.dart';
import '../../providers/checklist_provider.dart';
import 'checklist_template_form_screen.dart';

class ChecklistTemplatesScreen extends StatefulWidget {
  const ChecklistTemplatesScreen({super.key});

  @override
  State<ChecklistTemplatesScreen> createState() => _ChecklistTemplatesScreenState();
}

class _ChecklistTemplatesScreenState extends State<ChecklistTemplatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChecklistProvider>(context, listen: false).loadChecklists();
    });
  }

  // ==================== CONFIRMAÇÃO DE EXCLUSÃO ====================
  Future<void> _confirmDelete(BuildContext context, Checklist checklist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Checklist'),
        content: Text(
          'Tem certeza que deseja excluir o checklist "${checklist.name}"?\n\n'
              'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<ChecklistProvider>(context, listen: false);
      try {
        await provider.deleteChecklist(checklist.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checklist "${checklist.name}" excluído com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== CONFIRMAÇÃO DE EDIÇÃO (opcional) ====================
  Future<void> _confirmEdit(BuildContext context, Checklist checklist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Checklist'),
        content: const Text('Deseja editar este checklist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<ChecklistProvider>(context, listen: false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChecklistTemplateFormScreen(checklist: checklist),
        ),
      ).then((_) => provider.loadChecklists());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChecklistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modelos de Checklist'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToForm(null),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.checklists.isEmpty
          ? const Center(
        child: Text(
          'Nenhum checklist criado ainda.\nToque em + para criar o primeiro.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: () => provider.loadChecklists(),
        child: ListView.builder(
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
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                leading: const Icon(Icons.playlist_add_check, color: Colors.orange, size: 42),
                title: Text(
                  checklist.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                subtitle: Text(
                  '$totalGroups grupos • $totalItems itens',
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _confirmEdit(context, checklist),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, checklist),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(null),
        label: const Text('Novo Checklist'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Navegação auxiliar
  void _navigateToForm(Checklist? checklist) {
    final provider = Provider.of<ChecklistProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistTemplateFormScreen(checklist: checklist),
      ),
    ).then((_) => provider.loadChecklists());
  }
}