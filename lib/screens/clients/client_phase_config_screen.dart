// lib/screens/clients/client_phase_config_screen.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/client_phase_config.dart';
import '../../providers/client_phase_config_provider.dart';
import '../../providers/checklist_provider.dart';

class ClientPhaseConfigScreen extends StatefulWidget {
  const ClientPhaseConfigScreen({super.key});

  @override
  State<ClientPhaseConfigScreen> createState() => _ClientPhaseConfigScreenState();
}

class _ClientPhaseConfigScreenState extends State<ClientPhaseConfigScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    print('📥 [LOAD] Carregando fases e checklists...');
    await Provider.of<ClientPhaseConfigProvider>(context, listen: false).loadPhases();
    await Provider.of<ChecklistProvider>(context, listen: false).loadChecklists(); // ← Novo método
  }

  @override
  Widget build(BuildContext context) {
    final phaseProvider = Provider.of<ClientPhaseConfigProvider>(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);

    final sortedPhases = List<ClientPhaseConfig>.from(phaseProvider.phases)
      ..sort((a, b) => a.phaseOrder.compareTo(b.phaseOrder));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de Fases'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPhaseForm(context),
          ),
        ],
      ),
      body: phaseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedPhases.isEmpty
          ? const Center(
        child: Text(
          'Nenhuma fase configurada ainda.\nClique em + para adicionar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sortedPhases.length,
        onReorder: (oldIndex, newIndex) async {
          if (newIndex > oldIndex) newIndex--;
          final currentProvider = Provider.of<ClientPhaseConfigProvider>(context, listen: false);
          final reordered = List<ClientPhaseConfig>.from(sortedPhases);
          final item = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, item);

          await currentProvider.reorderPhases(reordered);
          await _loadData();
        },
        itemBuilder: (context, index) {
          final phase = sortedPhases[index];

          // Verifica se existe checklist vinculado (nova estrutura)
          final hasChecklist = checklistProvider.checklists.isNotEmpty;

          return Card(
            key: ValueKey(phase.id),
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.drag_handle, color: Colors.grey),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(int.parse(phase.color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.timeline, color: Colors.white, size: 20),
                  ),
                ],
              ),
              title: Text(
                phase.phaseName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ordem: ${phase.phaseOrder}'),
                  const SizedBox(height: 4),

                  if (phase.requiresChecklist)
                    Consumer<ChecklistProvider>(
                      builder: (context, checklistProvider, _) {
                        final checklist = checklistProvider.checklists.firstWhereOrNull(
                              (c) => c.id == phase.checklistId,
                        );

                        return Row(
                          children: [
                            Icon(
                              checklist != null ? Icons.check_circle : Icons.warning_amber_rounded,
                              size: 16,
                              color: checklist != null ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                checklist != null
                                    ? checklist.name
                                    : 'Checklist obrigatório (não vinculado)',
                                style: TextStyle(
                                  color: checklist != null ? Colors.green : Colors.orange,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    const Text(
                      'Não exige checklist',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: phase.isActive,
                    onChanged: (value) async {
                      final updated = phase.copyWith(isActive: value);
                      await Provider.of<ClientPhaseConfigProvider>(context, listen: false)
                          .updatePhase(updated);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showPhaseForm(context, phase: phase),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, phase),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== FORMULÁRIO DE FASE ====================
  // ==================== FORMULÁRIO DE FASE (Atualizado) ====================
  Future<void> _showPhaseForm(BuildContext context, {ClientPhaseConfig? phase}) async {
    final isEditing = phase != null;

    final nameController = TextEditingController(text: phase?.phaseName);
    final orderController = TextEditingController(text: phase?.phaseOrder.toString());
    String selectedColor = phase?.color ?? '#2196F3';
    bool requiresChecklist = phase?.requiresChecklist ?? false;
    int? selectedChecklistId = phase?.checklistId;   // ← Novo

    // Carrega checklists se ainda não carregou
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    if (checklistProvider.checklists.isEmpty) {
      await checklistProvider.loadChecklists();
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Fase' : 'Nova Fase'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome da Fase'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(labelText: 'Ordem'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Cor da Fase:'),
                Wrap(
                  spacing: 8,
                  children: [
                    '#1976D2', '#2196F3', '#03A9F4', '#00BCD4',
                    '#FF9800', '#F57C00', '#388E3C', '#4CAF50'
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Switch para exigir checklist
                SwitchListTile(
                  title: const Text('Exige Checklist para avançar'),
                  subtitle: const Text('O cliente só poderá passar para a próxima fase após concluir o checklist'),
                  value: requiresChecklist,
                  onChanged: (val) => setDialogState(() => requiresChecklist = val),
                ),

                // ← NOVO: Seletor de Checklist (só aparece se exige checklist)
                if (requiresChecklist) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: selectedChecklistId,
                    decoration: const InputDecoration(
                      labelText: 'Checklist Obrigatório',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Selecione um checklist'),
                    items: checklistProvider.checklists.map((checklist) {
                      return DropdownMenuItem<int>(
                        value: checklist.id,
                        child: Text(checklist.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedChecklistId = value);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final order = int.tryParse(orderController.text) ?? 999;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome da fase é obrigatório')),
                  );
                  return;
                }

                if (requiresChecklist && selectedChecklistId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione um checklist obrigatório')),
                  );
                  return;
                }

                final newPhase = ClientPhaseConfig(
                  id: phase?.id,
                  phaseName: name,
                  phaseOrder: order,
                  color: selectedColor,
                  requiresChecklist: requiresChecklist,
                  checklistId: requiresChecklist ? selectedChecklistId : null,
                );

                final provider = Provider.of<ClientPhaseConfigProvider>(context, listen: false);

                try {
                  if (isEditing) {
                    await provider.updatePhase(newPhase);
                  } else {
                    await provider.addPhase(newPhase);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadData(); // Recarrega a lista
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text(isEditing ? 'Salvar' : 'Criar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ClientPhaseConfig phase) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Fase?'),
        content: Text('Tem certeza que deseja excluir "${phase.phaseName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && phase.id != null) {
      await Provider.of<ClientPhaseConfigProvider>(context, listen: false)
          .deletePhase(phase.id);
    }
  }
}