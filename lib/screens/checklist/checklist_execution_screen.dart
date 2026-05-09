import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/checklist_provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/client.dart';

class ChecklistExecutionScreen extends StatefulWidget {
  final int phaseConfigId;
  final int? clientId;
  final Client? client;

  const ChecklistExecutionScreen({
    super.key,
    required this.phaseConfigId,
    this.clientId,
    this.client,
  });

  @override
  State<ChecklistExecutionScreen> createState() => _ChecklistExecutionScreenState();
}

class _ChecklistExecutionScreenState extends State<ChecklistExecutionScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String _checklistName = "Carregando...";

  Map<String, Map<String, List<Map<String, dynamic>>>> _data = {};
  Map<String, bool> _naGroup = {};

  final TextEditingController _responsibleNameController = TextEditingController();
  final TextEditingController _responsibleContactController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadChecklistItems();
  }

  @override
  void dispose() {
    _responsibleNameController.dispose();
    _responsibleContactController.dispose();
    super.dispose();
  }

  Future<void> _loadChecklistItems() async {
    // ... (seu código de load permanece igual)
    setState(() => _isLoading = true);
    _errorMessage = null;

    try {
      final checklistsData = await Supabase.instance.client
          .from('checklists')
          .select('*, groups:checklist_groups(*, subgroups:checklist_subgroups(*, items:checklist_items(*)))')
          .order('order_index')
          .limit(1);

      if (checklistsData.isEmpty) {
        setState(() => _errorMessage = 'Nenhum checklist encontrado');
        return;
      }

      final checklist = checklistsData.first;
      _checklistName = checklist['name'] as String? ?? 'Checklist';

      Map<String, Map<String, List<Map<String, dynamic>>>> data = {};
      Map<String, bool> naGroup = {};

      final groups = checklist['groups'] as List<dynamic>? ?? [];

      for (final group in groups) {
        final groupTitle = group['title'] as String? ?? 'Grupo';
        final subgroups = group['subgroups'] as List<dynamic>? ?? [];

        Map<String, List<Map<String, dynamic>>> subgroupMap = {};

        for (final subgroup in subgroups) {
          final subgroupTitle = subgroup['title'] as String? ?? 'Subgrupo';
          final items = subgroup['items'] as List<dynamic>? ?? [];

          subgroupMap[subgroupTitle] = items.map((item) => {
            'id': item['id'],
            'title': item['title'] as String? ?? 'Item sem título',
            'type': item['type'] as String? ?? 'sn',
            'status': 'pendente',
            'observation': '',
            'photos': <String>[],
          }).toList();
        }

        data[groupTitle] = subgroupMap;
        naGroup[groupTitle] = false;
      }

      setState(() {
        _data = data;
        _naGroup = naGroup;
        _isLoading = false;
      });
      print('✅ Checklist carregado com ${_data.length} grupos');
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao carregar: $e');
      _isLoading = false;
    }
  }

  void _toggleGroupNA(String groupTitle, bool value) {
    setState(() {
      _naGroup[groupTitle] = value;
      if (value) {
        final subgroups = _data[groupTitle]!;
        for (final subEntry in subgroups.entries) {
          for (var item in subEntry.value) {
            item['status'] = 'na';
            item['observation'] = 'Não se aplica ao cliente';
            item['photos'] = <String>[];
          }
        }
      } else {
        final subgroups = _data[groupTitle]!;
        for (final subEntry in subgroups.entries) {
          for (var item in subEntry.value) {
            item['status'] = 'pendente';
            item['observation'] = '';
            item['photos'] = <String>[];
          }
        }
      }
    });
  }

  void _updateItem(String groupTitle, String subgroupTitle, int itemIndex, String status) {
    setState(() {
      final item = _data[groupTitle]?[subgroupTitle]?[itemIndex];
      if (item == null) return;
      item['status'] = status;
      if (status != 'nao') {
        item['observation'] = '';
        item['photos'] = <String>[];
      }
    });
  }

  void _updateObservation(String groupTitle, String subgroupTitle, int itemIndex, String observation) {
    setState(() {
      _data[groupTitle]?[subgroupTitle]?[itemIndex]['observation'] = observation;
    });
  }

  // ==================== VALIDAÇÃO CORRIGIDA ====================
  bool _allItemsAreAnswered() {
    print('🔍 Iniciando verificação de pendentes...');
    int pendingCount = 0;

    _data.forEach((groupTitle, subgroups) {
      final isGroupNA = _naGroup[groupTitle] ?? false;
      if (isGroupNA) {
        print('   → Grupo "$groupTitle" marcado como N/A → ignorado');
        return;
      }

      subgroups.forEach((subgroupTitle, items) {
        for (var item in items) {
          final status = (item['status'] as String).toLowerCase();
          final isTextType = (item['type'] as String?) == 'text';

          if (isTextType) {
            print('   → Item texto ignorado: ${item['title']}');
            continue; // textos livres não são obrigatórios
          }

          if (status == 'pendente') {
            pendingCount++;
            print('   → ⚠️ Item PENDENTE: ${item['title']} (status: $status)');
          } else {
            print('   → OK: ${item['title']} = $status');
          }
        }
      });
    });

    print('✅ Verificação finalizada. Pendentes: $pendingCount');
    return pendingCount == 0;
  }

  Future<void> _concluirChecklist() async {
    print('🚀 === INICIANDO CONCLUSÃO DO CHECKLIST ===');

    if (_responsibleNameController.text.trim().isEmpty || _responsibleContactController.text.trim().isEmpty) {
      print('❌ Campos do responsável vazios');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha responsável e contato'), backgroundColor: Colors.red));
      return;
    }

    if (!_allItemsAreAnswered()) {
      print('❌ Ainda existem itens pendentes');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os itens de seleção devem ser marcados (SIM, NÃO ou N/A)'), backgroundColor: Colors.orange),
      );
      return;
    }

    print('✅ Todos os campos obrigatórios OK. Prosseguindo com salvamento...');

    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);

    final effectiveClientId = widget.clientId ?? widget.client?.id ?? 0;
    final currentEmployeeId = employeeProvider.currentEmployee?.id;

    try {
      final executionId = await checklistProvider.saveExecution(
        phaseConfigId: widget.phaseConfigId,
        clientId: effectiveClientId,
        employeeId: currentEmployeeId,
        executionData: _data,
        naGroups: _naGroup,
        responsibleName: _responsibleNameController.text.trim(),
        responsibleContact: _responsibleContactController.text.trim(),
      );

      print('✅ Execução salva com sucesso! ID: $executionId');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checklist salvo com sucesso!'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Erro ao salvar execução: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
    }
  }

  // ==================== BUILD (com miniaturas) ====================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Executar Checklist')),
        body: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_checklistName), backgroundColor: Colors.teal),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // Responsável
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informações da Execução', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _responsibleNameController,
                    decoration: const InputDecoration(labelText: 'Responsável na obra *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _responsibleContactController,
                    decoration: const InputDecoration(labelText: 'Contato *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),

          // Grupos
          ..._data.keys.map((groupTitle) {
            final subgroups = _data[groupTitle]!;
            final isGroupNA = _naGroup[groupTitle] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(groupTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                        Row(
                          children: [
                            const Text('Não se aplica'),
                            Checkbox(value: isGroupNA, onChanged: (v) => _toggleGroupNA(groupTitle, v ?? false)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  ...subgroups.entries.map((subEntry) {
                    final subgroupTitle = subEntry.key;
                    final items = subEntry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(subgroupTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.teal)),
                        ),
                        ...items.asMap().entries.map((itemEntry) {
                          final itemIndex = itemEntry.key;
                          final item = itemEntry.value;
                          final status = item['status'] as String;
                          final isTextType = (item['type'] as String?) == 'text';

                          return Container(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(item['title'] as String, style: const TextStyle(fontSize: 15))),
                                    if (!isTextType)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildOptionButton(groupTitle, subgroupTitle, itemIndex, 'sim', status == 'sim', 'Sim', Colors.green),
                                          const SizedBox(width: 4),
                                          _buildOptionButton(groupTitle, subgroupTitle, itemIndex, 'nao', status == 'nao', 'Não', Colors.red),
                                          const SizedBox(width: 4),
                                          _buildOptionButton(groupTitle, subgroupTitle, itemIndex, 'na', status == 'na', 'N/A', Colors.grey),
                                        ],
                                      ),
                                  ],
                                ),

                                if (status == 'nao' && !isGroupNA) ...[
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: const InputDecoration(labelText: 'Motivo / Pendência', border: OutlineInputBorder(), isDense: true),
                                    onChanged: (text) => _updateObservation(groupTitle, subgroupTitle, itemIndex, text),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _addPhoto(groupTitle, subgroupTitle, itemIndex),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Adicionar Foto'),
                                  ),
                                ],

                                // Miniatura das fotos
                                if ((item['photos'] as List?)?.isNotEmpty ?? false)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 8,
                                      children: (item['photos'] as List).map((url) => ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(url as String, width: 70, height: 70, fit: BoxFit.cover),
                                      )).toList(),
                                    ),
                                  ),

                                if (isTextType)
                                  TextField(
                                    decoration: const InputDecoration(labelText: 'Resposta', border: OutlineInputBorder()),
                                    onChanged: (text) => _updateObservation(groupTitle, subgroupTitle, itemIndex, text),
                                  ),

                                const Divider(height: 16),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _concluirChecklist,
        label: const Text('Concluir Checklist'),
        icon: const Icon(Icons.done_all),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildOptionButton(String groupTitle, String subgroupTitle, int itemIndex, String value, bool isSelected, String label, Color color) {
    return GestureDetector(
      onTap: () => _updateItem(groupTitle, subgroupTitle, itemIndex, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
      ),
    );
  }

  Future<void> _addPhoto(String groupTitle, String subgroupTitle, int itemIndex) async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles == null || pickedFiles.isEmpty) return;

    List<String> newPhotos = [];
    for (var file in pickedFiles) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final bytes = await file.readAsBytes();

        final uploadedPath = await Supabase.instance.client.storage
            .from('checklist_photos')
            .uploadBinary(fileName, bytes);

        final publicUrl = Supabase.instance.client.storage.from('checklist_photos').getPublicUrl(uploadedPath);
        newPhotos.add(publicUrl);
      } catch (e) {
        print('Erro ao enviar foto: $e');
      }
    }

    if (newPhotos.isNotEmpty) {
      setState(() {
        final current = _data[groupTitle]?[subgroupTitle]?[itemIndex]['photos'] as List? ?? [];
        _data[groupTitle]?[subgroupTitle]?[itemIndex]['photos'] = [...current, ...newPhotos];
      });
    }
  }
}