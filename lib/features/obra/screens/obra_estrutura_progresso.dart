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

class _ObraEstruturaProgressoState extends State<ObraEstruturaProgresso>
    with SingleTickerProviderStateMixin {
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
          .order('ordem');

      ambientesDaObra = List.from(resAmbientes);

      // Tenta achar a fase ativa da obra
      final faseAtualId = widget.obra.faseAtualId;
      faseAtualIndex = fases.indexWhere((f) => f['fase_id'] == faseAtualId);

      if (faseAtualIndex == -1) {
        // Fallback: primeira não concluída
        faseAtualIndex = fases.indexWhere((f) => (f['status'] ?? '') != 'concluido');
      }
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
        // ===================== TABS DE FASES =====================
        Container(
          color: Colors.grey.shade50,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade700,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Colors.blue.shade100,           // ← azul clarinho para a aba selecionada
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: fases.asMap().entries.map((entry) {
              final index = entry.key;
              final faseData = entry.value;
              final fase = faseData['fase'] ?? {};
              final nome = fase['nome']?.toString() ?? 'Fase ${index + 1}';
              final isCurrent = index == faseAtualIndex; // fase ativa da obra

              final servicos = _getServicosDaFase(faseData['fase_id'] as String?);
              final total = servicos.length;
              final concluidos =
                  servicos.where((s) => (s['status'] ?? '') == 'concluido').length;

              return Tab(
                height: 54,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    // Só a fase atual da obra fica verde forte
                    color: isCurrent ? Colors.teal.shade400 : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrent
                        ? null
                        : Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nome,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                          color: isCurrent ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$concluidos/$total",
                        style: TextStyle(
                          fontSize: 11,
                          // Contador mais brilhante na fase atual
                          color: isCurrent ? Colors.white : Colors.grey.shade600,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ===================== CONTEÚDO =====================
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: fases.map((faseData) {
              final servicos = _getServicosDaFase(faseData['fase_id'] as String?);
              return _AmbienteGridView(
                ambientes: ambientesDaObra,
                servicosDaFase: servicos,
                onGrupoTap: (grupoNome, servicosGrupo) =>
                    _showGrupoPopup(context, grupoNome, servicosGrupo),
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
          width: 680,
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
                color: isEven ? Colors.grey[50] : Colors.white,
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }
}

// ===================== GRID DE AMBIENTES (CARDS MENORES) =====================
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
        crossAxisCount: 7, // ← mais cards por linha
        childAspectRatio: 1.0, // ← cards mais baixos/compactos
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: ambientes.length,
      itemBuilder: (context, index) {
        final amb = ambientes[index];
        final servicos = (amb['obra_servico'] as List<dynamic>? ?? [])
            .where((s) => servicosDaFase.any((sf) => sf['id'] == s['id']))
            .toList();

        final concluidos =
            servicos.where((s) => (s['status'] ?? '') == 'concluido').length;
        final total = servicos.length;
        final progresso = total == 0 ? 0.0 : concluidos / total;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome do ambiente
                Row(
                  children: [
                    const Icon(Icons.room, color: Colors.purple, size: 18),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        amb['nome'] ?? 'Ambiente',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progresso
                Text(
                  "$concluidos / $total",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progresso,
                  minHeight: 5,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(
                    progresso == 1.0 ? Colors.green : Colors.teal,
                  ),
                ),
                const SizedBox(height: 10),

                // Grupos compactos
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
    if (servicos.isEmpty) {
      return const Center(
        child: Text("—", style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    final Map<String, List<dynamic>> porGrupo = {};
    for (var s in servicos) {
      final grupoNome = s['grupo']?['nome'] ?? 'Sem Grupo';
      porGrupo.putIfAbsent(grupoNome, () => []).add(s);
    }

    return SingleChildScrollView(
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: porGrupo.entries.map((entry) {
          final grupoNome = entry.key;
          final servs = entry.value;
          final concluidos =
              servs.where((s) => (s['status'] ?? '') == 'concluido').length;

          return InkWell(
            onTap: () => onGrupoTap(grupoNome, servs),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                "$grupoNome ($concluidos/${servs.length})",
                style: const TextStyle(fontSize: 11),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}