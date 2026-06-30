// lib/features/obra/screens/obra_estrutura_hierarquia.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';

class ObraEstruturaHierarquia extends StatefulWidget {
  final Obra obra;

  const ObraEstruturaHierarquia({super.key, required this.obra});

  @override
  State<ObraEstruturaHierarquia> createState() => _ObraEstruturaHierarquiaState();
}

class _ObraEstruturaHierarquiaState extends State<ObraEstruturaHierarquia> {
  List<Map<String, dynamic>> pavimentos = [];
  bool isLoading = true;
  bool _allExpanded = false; // Inicia recolhido

  @override
  void initState() {
    super.initState();
    _carregarHierarquia();
  }

  Future<void> _carregarHierarquia() async {
    setState(() => isLoading = true);
    try {
      debugPrint("🔄 Carregando hierarquia para obra: ${widget.obra.id}");

      final res = await Supabase.instance.client
          .from('obra_ambiente')
          .select('''
            *,
            pavimento:obra_piso_id (id, nome, ordem),
            obra_servico(*, servico(*), grupo:servico_grupo(*))
          ''')
          .eq('obra_id', widget.obra.id)
          .order('pavimento(ordem)');

      final Map<String, Map<String, dynamic>> pavMap = {};

      for (var amb in res) {
        final pav = amb['pavimento'] as Map<String, dynamic>? ?? {};
        final pavId = pav['id']?.toString() ?? 'sem_pav';

        if (!pavMap.containsKey(pavId)) {
          pavMap[pavId] = {
            'id': pav['id'],
            'nome': pav['nome'] ?? 'Pavimento sem nome',
            'ordem': pav['ordem'] ?? 0,
            'ambientes': <Map<String, dynamic>>[],
          };
        }

        pavMap[pavId]!['ambientes'].add(amb as Map<String, dynamic>);
      }

      // Ordena os pavimentos por ordem
      pavimentos = pavMap.values.toList()
        ..sort((a, b) => (a['ordem'] as int).compareTo(b['ordem'] as int));

      debugPrint("✅ Hierarquia carregada: ${pavimentos.length} pavimentos");
      for (var p in pavimentos) {
        debugPrint("   Pavimento: ${p['nome']} | Ordem: ${p['ordem']} | Ambientes: ${(p['ambientes'] as List).length}");
      }
    } catch (e, stack) {
      debugPrint("❌ Erro ao carregar hierarquia: $e");
      debugPrint("Stack: $stack");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _toggleAllExpanded() {
    setState(() => _allExpanded = !_allExpanded);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pavimentos.isEmpty) {
      return const Center(child: Text("Nenhuma estrutura cadastrada para esta obra"));
    }

    return RefreshIndicator(
      onRefresh: _carregarHierarquia,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Estrutura da Obra", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _toggleAllExpanded,
                  icon: Icon(_allExpanded ? Icons.unfold_less : Icons.unfold_more),
                  label: Text(_allExpanded ? "Recolher Tudo" : "Expandir Tudo"),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pavimentos.length,
              itemBuilder: (context, index) {
                final piso = pavimentos[index];
                final ambientes = piso['ambientes'] as List<dynamic>? ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  child: ExpansionTile(
                    initiallyExpanded: _allExpanded,
                    leading: const Icon(Icons.layers, color: Colors.teal),
                    title: Text(
                      piso['nome'] ?? 'Pavimento sem nome',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${ambientes.length} ambientes", style: const TextStyle(fontSize: 13)),
                    children: [
                      ...ambientes.map((amb) {
                        final servicos = amb['obra_servico'] as List<dynamic>? ?? [];

                        return ExpansionTile(
                          initiallyExpanded: _allExpanded,
                          leading: const Icon(Icons.room, color: Colors.purple, size: 24),
                          title: Text(amb['nome'] ?? 'Ambiente', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text("${servicos.length} serviços", style: const TextStyle(fontSize: 13)),
                          children: [
                            if (servicos.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                child: _buildServicosPorGrupo(servicos),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text("Nenhum serviço", style: TextStyle(color: Colors.grey)),
                              ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicosPorGrupo(List<dynamic> servicos) {
    final Map<String, List<dynamic>> porGrupo = {};

    for (var s in servicos) {
      final grupoNome = s['grupo']?['nome'] ?? 'Sem Grupo';
      porGrupo.putIfAbsent(grupoNome, () => []).add(s);
    }

    return Column(
      children: porGrupo.entries.map((entry) {
        final grupoNome = entry.key;
        final servicosDoGrupo = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            initiallyExpanded: _allExpanded,
            leading: const Icon(Icons.folder, color: Colors.amber, size: 26),
            title: Text(grupoNome, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("${servicosDoGrupo.length} serviços"),
            children: servicosDoGrupo.map((s) {
              final servico = s['servico'] ?? {};
              final descricao = (s['observacoes'] ?? '').toString().trim();

              final titulo = descricao.isNotEmpty
                  ? "${servico['nome'] ?? ''} — $descricao"
                  : (servico['nome'] ?? '');

              return ListTile(
                dense: true,
                leading: const Icon(Icons.build_circle, size: 20, color: Colors.teal),
                title: Text(titulo),
                trailing: Chip(
                  label: Text((s['status'] ?? 'pendente').toUpperCase()),
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  labelStyle: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}