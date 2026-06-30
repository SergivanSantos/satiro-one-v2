// lib/features/obra/screens/obra_estrutura_progresso.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';

class ObraEstruturaProgresso extends StatefulWidget {
  final Obra obra;
  const ObraEstruturaProgresso({super.key, required this.obra});

  @override
  State<ObraEstruturaProgresso> createState() => _ObraEstruturaProgressoState();
}

class _ObraEstruturaProgressoState extends State<ObraEstruturaProgresso> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> fases = [];
  List<Map<String, dynamic>> ambientesDaObra = [];
  bool isLoading = true;
  TabController? _tabController;

  int faseAtualIndex = 0;

  @override
  void initState() {
    super.initState();
    _carregarProgresso();
  }

  Future<void> _carregarProgresso() async {
    setState(() => isLoading = true);
    try {
      final resFases = await Supabase.instance.client
          .from('obra_fase')
          .select('*, fase(*)')
          .eq('obra_id', widget.obra.id);

      fases = List.from(resFases);

      fases.sort((a, b) {
        final ordemA = a['fase']?['ordem'] as int? ?? 999;
        final ordemB = b['fase']?['ordem'] as int? ?? 999;
        return ordemA.compareTo(ordemB);
      });

      final resAmbientes = await Supabase.instance.client
          .from('obra_ambiente')
          .select('*, obra_servico(*, servico(*), grupo:servico_grupo(*))')
          .eq('obra_id', widget.obra.id)
          .order('nome');

      ambientesDaObra = List.from(resAmbientes);

      faseAtualIndex = fases.indexWhere((f) => (f['status'] ?? '') != 'concluido');
      if (faseAtualIndex == -1 || faseAtualIndex >= fases.length) {
        faseAtualIndex = fases.isNotEmpty ? fases.length - 1 : 0;
      }

      _tabController?.dispose();
      if (fases.isNotEmpty) {
        _tabController = TabController(
          length: fases.length,
          vsync: this,
          initialIndex: faseAtualIndex.clamp(0, fases.length - 1),
        );
      }

      debugPrint("✅ ${fases.length} fases carregadas e ordenadas corretamente");
    } catch (e, stack) {
      debugPrint("❌ Erro ao carregar progresso: $e");
      debugPrint("Stack: $stack");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fases.isEmpty) {
      return const Center(child: Text("Nenhuma fase configurada para esta obra"));
    }

    return Column(
      children: [
        Container(
          color: Colors.teal[50],
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.teal[900],
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: fases.asMap().entries.map((entry) {
              final index = entry.key;
              final faseData = entry.value;
              final fase = faseData['fase'] ?? {};
              final nome = fase['nome']?.toString() ?? 'Fase ${index + 1}';

              final servicos = _getServicosDaFase(faseData['fase_id'] as String?);
              final total = servicos.length;
              final concluidos = servicos.where((s) => (s['status'] ?? '') == 'concluido').length;
              final isCurrent = index == faseAtualIndex;

              return Tab(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(nome, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                    Text(
                      "$concluidos/$total",
                      style: TextStyle(fontSize: 11, color: isCurrent ? Colors.teal : Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: fases.map((faseData) {
              final servicos = _getServicosDaFase(faseData['fase_id'] as String?);
              return _AmbienteGridView(
                ambientes: ambientesDaObra,
                servicosDaFase: servicos,
                onGrupoTap: (grupoNome, servicosGrupo) => _showGrupoPopup(context, grupoNome, servicosGrupo),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<dynamic> _getServicosDaFase(String? faseId) {
    if (faseId == null) return [];
    final List<dynamic> todos = [];
    for (var amb in ambientesDaObra) {
      final servicos = amb['obra_servico'] as List<dynamic>? ?? [];
      todos.addAll(servicos.where((s) => s['fase_id'] == faseId));
    }
    return todos;
  }

  void _showGrupoPopup(BuildContext context, String grupoNome, List<dynamic> servicos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Grupo: $grupoNome"),
        content: SizedBox(
          width: 680,           // ← Largura que você gostou
          height: 520,
          child: ListView.builder(
            itemCount: servicos.length,
            itemBuilder: (context, index) {
              final s = servicos[index];
              final servico = s['servico'] ?? {};
              final descricao = (s['observacoes'] ?? '').toString().trim();

              final titulo = descricao.isNotEmpty
                  ? "${servico['nome'] ?? ''} — $descricao"
                  : (servico['nome'] ?? '');

              final isEven = index % 2 == 0;

              return Container(
                color: isEven ? Colors.grey[50] : Colors.white, // ← Linhas alternadas
                child: ListTile(
                  leading: const Icon(Icons.build_circle, color: Colors.teal),
                  title: Text(titulo),
                  trailing: Chip(
                    label: Text((s['status'] ?? 'pendente').toUpperCase()),
                    backgroundColor: Colors.orange.withOpacity(0.2),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
  }
}

class _AmbienteGridView extends StatelessWidget {
  final List<Map<String, dynamic>> ambientes;
  final List<dynamic> servicosDaFase;
  final Function(String, List<dynamic>) onGrupoTap;

  const _AmbienteGridView({
    required this.ambientes,
    required this.servicosDaFase,
    required this.onGrupoTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: ambientes.length,
      itemBuilder: (context, index) {
        final amb = ambientes[index];
        final servicos = (amb['obra_servico'] as List<dynamic>? ?? [])
            .where((s) => servicosDaFase.any((sf) => sf['id'] == s['id']))
            .toList();

        final concluidos = servicos.where((s) => (s['status'] ?? '') == 'concluido').length;

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.room, color: Colors.purple, size: 22),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        amb['nome'] ?? 'Ambiente',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "$concluidos / ${servicos.length}",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: servicos.isEmpty ? 0 : concluidos / servicos.length,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation(Colors.teal),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildGruposCompactos(context, servicos),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGruposCompactos(BuildContext context, List<dynamic> servicos) {
    if (servicos.isEmpty) return const Center(child: Text("—", style: TextStyle(color: Colors.grey)));

    final Map<String, List<dynamic>> porGrupo = {};
    for (var s in servicos) {
      final grupoNome = s['grupo']?['nome'] ?? 'Sem Grupo';
      porGrupo.putIfAbsent(grupoNome, () => []).add(s);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: porGrupo.entries.map((entry) {
        final grupoNome = entry.key;
        final servs = entry.value;
        final concluidos = servs.where((s) => (s['status'] ?? '') == 'concluido').length;

        return InkWell(
          onTap: () => onGrupoTap(grupoNome, servs),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "$grupoNome ($concluidos/${servs.length})",
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
        );
      }).toList(),
    );
  }
}