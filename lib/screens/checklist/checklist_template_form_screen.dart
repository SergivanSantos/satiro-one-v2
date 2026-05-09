// lib/screens/checklist/checklist_template_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/checklist.dart';
import '../../models/checklist_group.dart';
import '../../models/checklist_subgroup.dart';
import '../../models/checklist_item.dart';
import '../../providers/checklist_provider.dart';

class ChecklistTemplateFormScreen extends StatefulWidget {
  final Checklist? checklist;

  const ChecklistTemplateFormScreen({
    super.key,
    this.checklist,
  });

  @override
  State<ChecklistTemplateFormScreen> createState() => _ChecklistTemplateFormScreenState();
}

class _ChecklistTemplateFormScreenState extends State<ChecklistTemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _checklistName;
  final List<ChecklistGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _checklistName = widget.checklist?.name ?? 'Novo Checklist';
    if (widget.checklist != null) {
      _groups.addAll(widget.checklist!.groups);
    }
  }

  // ==================== GRUPO PRINCIPAL ====================
  void _addGroup() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Grupo Principal'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome do grupo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _groups.add(ChecklistGroup(
                    id: 0,
                    title: controller.text.trim(),
                    orderIndex: _groups.length,
                    subgroups: [],
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _editGroup(int index) {
    final controller = TextEditingController(text: _groups[index].title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Grupo Principal'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _groups[index] = _groups[index].copyWith(title: controller.text.trim());
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _deleteGroup(int index) {
    setState(() => _groups.removeAt(index));
  }

  // ==================== SUBGRUPO ====================
  void _addSubgroup(int groupIndex) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Subgrupo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome do subgrupo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  final group = _groups[groupIndex];
                  group.subgroups.add(ChecklistSubgroup(
                    id: 0,
                    title: controller.text.trim(),
                    orderIndex: group.subgroups.length,
                    items: [],
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Adicionar Subgrupo'),
          ),
        ],
      ),
    );
  }

  void _editSubgroup(int groupIndex, int subgroupIndex) {
    final subgroup = _groups[groupIndex].subgroups[subgroupIndex];
    final controller = TextEditingController(text: subgroup.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Subgrupo'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _groups[groupIndex].subgroups[subgroupIndex] = subgroup.copyWith(title: controller.text.trim());
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _deleteSubgroup(int groupIndex, int subgroupIndex) {
    setState(() {
      _groups[groupIndex].subgroups.removeAt(subgroupIndex);
    });
  }

  // ==================== ITEM ====================
  void _addItemToSubgroup(int groupIndex, int subgroupIndex) {
    final titleController = TextEditingController();
    String selectedType = 'sn';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ← MUDANÇA AQUI
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Descrição do item',
                hintText: 'Escreva a descrição completa do item...\n\nExemplo:\n1. Verificar se o cabo está conectado\n2. Testar tensão\n3. Conferir aterramento',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,           // permite várias linhas
              minLines: 3,           // altura mínima
              textInputAction: TextInputAction.newline, // Enter cria nova linha
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Tipo de resposta'),
              items: const [
                DropdownMenuItem(value: 'sn', child: Text('Sim / Não / N.A')),
                DropdownMenuItem(value: 'text', child: Text('Texto livre')),
              ],
              onChanged: (v) => selectedType = v ?? 'sn',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                setState(() {
                  final subgroup = _groups[groupIndex].subgroups[subgroupIndex];
                  subgroup.items.add(ChecklistItem(
                    id: 0,
                    title: titleController.text.trim(),
                    type: selectedType,
                    isRequired: true,
                    orderIndex: subgroup.items.length,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Adicionar Item'),
          ),
        ],
      ),
    );
  }

  void _editItem(int groupIndex, int subgroupIndex, int itemIndex) {
    final item = _groups[groupIndex].subgroups[subgroupIndex].items[itemIndex];
    final titleController = TextEditingController(text: item.title);
    String selectedType = item.type;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ← MUDANÇA AQUI
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Descrição do item',
                hintText: 'Escreva a descrição completa...\nUse Enter para novas linhas',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'Tipo de resposta'),
              items: const [
                DropdownMenuItem(value: 'sn', child: Text('Sim / Não / N.A')),
                DropdownMenuItem(value: 'text', child: Text('Texto livre')),
              ],
              onChanged: (v) => selectedType = v ?? 'sn',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                setState(() {
                  _groups[groupIndex].subgroups[subgroupIndex].items[itemIndex] = item.copyWith(
                    title: titleController.text.trim(),
                    type: selectedType,
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int groupIndex, int subgroupIndex, int itemIndex) {
    setState(() {
      _groups[groupIndex].subgroups[subgroupIndex].items.removeAt(itemIndex);
    });
  }

  Future<void> _saveTemplate() async {
    if (_checklistName.trim().isEmpty || _groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome do checklist e pelo menos um grupo são obrigatórios')),
      );
      return;
    }

    final provider = Provider.of<ChecklistProvider>(context, listen: false);

    try {
      if (widget.checklist != null && widget.checklist!.id != null) {
        // Modo EDIÇÃO
        await provider.updateChecklist(
          widget.checklist!.id!,
          _checklistName.trim(),
          List.from(_groups), // cópia para segurança
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist atualizado com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        // Modo CRIAÇÃO
        await provider.addChecklist(
          _checklistName.trim(),
          List.from(_groups),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist criado com sucesso!'), backgroundColor: Colors.green),
        );
      }

      Navigator.pop(context, true); // Retorna para tela anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.checklist == null ? 'Novo Checklist' : 'Editar Checklist'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              initialValue: _checklistName,
              decoration: const InputDecoration(
                labelText: 'Nome do Checklist',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _checklistName = v,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grupos Principais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.teal, size: 28),
                  onPressed: _addGroup,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _groups.isEmpty
                  ? const Center(
                child: Text(
                  'Clique no botão + para adicionar o primeiro Grupo Principal',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _groups.length,
                itemBuilder: (context, groupIndex) {
                  final group = _groups[groupIndex];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text(group.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () => _editGroup(groupIndex),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _deleteGroup(groupIndex),
                          ),
                        ],
                      ),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.add, color: Colors.orange),
                          title: const Text('Adicionar Subgrupo'),
                          onTap: () => _addSubgroup(groupIndex),
                        ),
                        ...group.subgroups.asMap().entries.map((entry) {
                          final subgroupIndex = entry.key;
                          final subgroup = entry.value;
                          return ExpansionTile(
                            title: Text(subgroup.title),
                            subtitle: Text('${subgroup.items.length} itens'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  onPressed: () => _editSubgroup(groupIndex, subgroupIndex),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _deleteSubgroup(groupIndex, subgroupIndex),
                                ),
                              ],
                            ),
                            children: [
                              ...subgroup.items.asMap().entries.map((itemEntry) {
                                final itemIndex = itemEntry.key;
                                final item = itemEntry.value;
                                return ListTile(
                                  dense: true,
                                  title: Text(item.title),
                                  subtitle: Text(item.type),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                        onPressed: () => _editItem(groupIndex, subgroupIndex, itemIndex),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                        onPressed: () => _deleteItem(groupIndex, subgroupIndex, itemIndex),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              ListTile(
                                leading: const Icon(Icons.add, color: Colors.teal),
                                title: const Text('Adicionar Item'),
                                onTap: () => _addItemToSubgroup(groupIndex, subgroupIndex),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveTemplate,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Checklist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}