// lib/features/servicos/screens/obra_servico_form_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../obra/models/obra.dart';
import '../models/servico.dart';

class SelectedService {
  final Servico servico;
  String? faseId;
  String? ambienteId;
  String? grupoId;
  String status = 'pendente';
  String? observacoes;
  int quantidade = 1;
  List<String> descricoes = [];

  SelectedService(this.servico) {
    descricoes = List.filled(quantidade, '', growable: true);
  }
}

class ObraServicoFormScreen extends StatefulWidget {
  final Obra obra;
  final Map<String, dynamic>? servicoExistente;

  const ObraServicoFormScreen({
    super.key,
    required this.obra,
    this.servicoExistente,
  });

  @override
  State<ObraServicoFormScreen> createState() => _ObraServicoFormScreenState();
}

class _ObraServicoFormScreenState extends State<ObraServicoFormScreen> {
  List<Servico> _servicosDisponiveis = [];
  List<Map<String, dynamic>> _fasesDaObra = [];
  List<Map<String, dynamic>> _ambientesDaObra = [];
  List<Map<String, dynamic>> _gruposDisponiveis = [];

  final List<SelectedService> _selectedServices = [];

  bool _isLoadingData = true;
  bool get isEditing => widget.servicoExistente != null;

  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoadingData = true);
    try {
      final resGrupos = await Supabase.instance.client
          .from('servico_grupo')
          .select()
          .eq('ativo', true)
          .order('ordem');
      _gruposDisponiveis = List.from(resGrupos);

      final resServicos = await Supabase.instance.client
          .from('servico')
          .select('*, categoria(nome)')
          .eq('ativo', true)
          .order('categoria(nome)')
          .order('nome');
      _servicosDisponiveis = resServicos.map<Servico>((s) => Servico.fromMap(s)).toList();

      final resFases = await Supabase.instance.client
          .from('obra_fase')
          .select('*, fase(*)')
          .eq('obra_id', widget.obra.id)
          .order('ordem', ascending: true);
      _fasesDaObra = List.from(resFases);

      final resAmbientes = await Supabase.instance.client
          .from('obra_ambiente')
          .select('*, pavimento(*)')
          .eq('obra_id', widget.obra.id)
          .order('nome');
      _ambientesDaObra = List.from(resAmbientes);

      if (widget.servicoExistente != null) {
        _carregarServicoParaEdicao(widget.servicoExistente!);
      }
    } catch (e) {
      debugPrint("❌ Erro ao carregar dados: $e");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _carregarServicoParaEdicao(Map<String, dynamic> item) {
    final servicoData = item['servico'] ?? {};
    final servico = Servico.fromMap(servicoData);

    final selected = SelectedService(servico);
    selected.faseId = item['fase_id'];
    selected.ambienteId = item['ambiente_id'];
    selected.grupoId = item['grupo_id'] ?? servicoData['grupo_id'];
    selected.status = item['status'] ?? 'pendente';
    selected.observacoes = item['observacoes'];
    selected.quantidade = 1;

    _selectedServices.add(selected);

    final categoria = servico.categoria ?? 'Sem categoria';
    _expandedCategories.add(categoria);
  }

  void _toggleService(Servico servico) {
    setState(() {
      final exists = _selectedServices.any((s) => s.servico.id == servico.id);
      if (exists) {
        _selectedServices.removeWhere((s) => s.servico.id == servico.id);
      } else {
        _selectedServices.add(SelectedService(servico));
      }
    });
  }

  Future<void> _salvarTodos() async {
    if (_selectedServices.isEmpty) return;

    try {
      List<Map<String, dynamic>> batch = [];

      for (var selected in _selectedServices) {
        for (int i = 0; i < selected.quantidade; i++) {
          batch.add({
            'obra_id': widget.obra.id,
            'servico_id': selected.servico.id,
            'fase_id': selected.faseId,
            'ambiente_id': selected.ambienteId,
            'grupo_id': selected.grupoId,
            'status': selected.status,
            'observacoes': selected.descricoes.length > i ? selected.descricoes[i] : selected.observacoes,
          });
        }
      }

      if (isEditing && widget.servicoExistente != null) {
        final item = widget.servicoExistente!;
        final selected = _selectedServices.first;
        await Supabase.instance.client.from('obra_servico').update({
          'servico_id': selected.servico.id,
          'fase_id': selected.faseId,
          'ambiente_id': selected.ambienteId,
          'grupo_id': selected.grupoId,
          'status': selected.status,
          'observacoes': selected.descricoes.isNotEmpty ? selected.descricoes[0] : selected.observacoes,
        }).eq('id', item['id']);
      } else {
        await Supabase.instance.client.from('obra_servico').insert(batch);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? "✅ Serviço atualizado!" : "${batch.length} registros salvos com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Serviço" : "Adicionar Serviços na Obra"),
        backgroundColor: Colors.teal[900],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: _buildServicosPorCategoria(),
            ),
          ),

          if (_selectedServices.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                border: Border(top: BorderSide(color: Colors.teal[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Selecionados: ${_selectedServices.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _salvarTodos,
                      child: Text(isEditing ? "SALVAR ALTERAÇÕES" : "SALVAR TODOS OS SERVIÇOS"),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildServicosPorCategoria() {
    final Map<String, List<Servico>> porCategoria = {};
    for (var s in _servicosDisponiveis) {
      final cat = s.categoria ?? 'Sem categoria';
      porCategoria.putIfAbsent(cat, () => []).add(s);
    }

    return porCategoria.entries.map((entry) {
      final categoria = entry.key;
      final servicos = entry.value;
      final isExpanded = _expandedCategories.contains(categoria);

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          title: Text(categoria.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          onExpansionChanged: (expanded) {
            if (expanded) _expandedCategories.add(categoria);
            else _expandedCategories.remove(categoria);
          },
          children: servicos.map((s) {
            final selected = _selectedServices.firstWhereOrNull((sel) => sel.servico.id == s.id);

            return Column(
              children: [
                CheckboxListTile(
                  value: selected != null,
                  title: Text(s.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onChanged: (_) => _toggleService(s),
                ),
                if (selected != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(52, 8, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: selected.faseId,
                                decoration: const InputDecoration(labelText: "Fase", isDense: true),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text("Sem fase")),
                                  ..._fasesDaObra.map((f) => DropdownMenuItem(value: f['fase_id'], child: Text(f['fase']?['nome']?.toString() ?? ''))),
                                ],
                                onChanged: (value) => setState(() => selected.faseId = value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: selected.ambienteId,
                                decoration: const InputDecoration(labelText: "Ambiente", isDense: true),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text("Sem ambiente")),
                                  ..._ambientesDaObra.map((a) => DropdownMenuItem(value: a['id'], child: Text(a['nome']?.toString() ?? ''))),
                                ],
                                onChanged: (value) => setState(() => selected.ambienteId = value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: selected.grupoId,
                                decoration: const InputDecoration(labelText: "Grupo", isDense: true),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text("Sem grupo")),
                                  ..._gruposDisponiveis.map((g) => DropdownMenuItem(value: g['id'], child: Text(g['nome']?.toString() ?? ''))),
                                ],
                                onChanged: (value) => setState(() => selected.grupoId = value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Quantidade
                        Row(
                          children: [
                            const Text("Quantidade:", style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(isDense: true),
                                controller: TextEditingController(text: selected.quantidade.toString()),
                                onChanged: (value) {
                                  final q = int.tryParse(value) ?? 1;
                                  setState(() {
                                    selected.quantidade = q.clamp(1, 20);
                                    // Ajusta lista de descrições
                                    if (selected.descricoes.length < selected.quantidade) {
                                      selected.descricoes.addAll(List.filled(selected.quantidade - selected.descricoes.length, ''));
                                    } else if (selected.descricoes.length > selected.quantidade) {
                                      selected.descricoes = selected.descricoes.sublist(0, selected.quantidade);
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Campos de descrição individuais
                        ...List.generate(selected.quantidade, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Descrição ${i + 1} (opcional)",
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              controller: TextEditingController(text: selected.descricoes.length > i ? selected.descricoes[i] : ''),
                              onChanged: (text) {
                                if (selected.descricoes.length > i) {
                                  selected.descricoes[i] = text;
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 1, indent: 52, endIndent: 16),
              ],
            );
          }).toList(),
        ),
      );
    }).toList();
  }
}

// Extensão para firstWhereOrNull
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}