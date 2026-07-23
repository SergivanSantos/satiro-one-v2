// lib/features/chamado/screens/admin/tabs/pendentes_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../obra/providers/obra_provider.dart';
import '../../../../servicos/providers/servico_provider.dart';
import '../../../../servicos/screens/obra_servico_form_screen.dart';
import '../../../providers/chamado_provider.dart';
import '../../../../atendimento/providers/atendimento_provider.dart';

class PendentesTab extends StatefulWidget {
  final VoidCallback onRefresh;
  final String? filialId;

  const PendentesTab({
    super.key,
    required this.onRefresh,
    this.filialId,
  });

  @override
  State<PendentesTab> createState() => _PendentesTabState();
}

class _PendentesTabState extends State<PendentesTab> {
  bool _isLoading = false;

  Future<void> _atualizarPendentes() async {
    setState(() => _isLoading = true);
    try {
      final servicoProvider = context.read<ServicoProvider>();
      final chamadoProvider = context.read<ChamadoProvider>();

      await chamadoProvider.carregarTodosChamados();

      final obrasIds = chamadoProvider.chamados
          .map((c) => c.obraId)
          .where((id) => id.isNotEmpty)
          .toSet();

      for (var obraId in obrasIds) {
        await servicoProvider.carregarServicosDaObra(obraId, null);
      }
    } catch (e) {
      debugPrint("Erro ao atualizar pendentes: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final servicoProvider = context.watch<ServicoProvider>();
    final obraProvider = context.watch<ObraProvider>();
    final chamadoProvider = context.watch<ChamadoProvider>();
    final atendimentoProvider = context.watch<AtendimentoProvider>();

    final List<Map<String, dynamic>> pendentes = [];

    for (var chamado in chamadoProvider.chamados) {
      final servicos = servicoProvider.getServicosDaObra(chamado.obraId);

      for (var s in servicos) {
        final status = (s['status'] ?? '').toString().toLowerCase().trim();
        if (status.contains('pendente') || status == 'nao_iniciado') {
          final servicoData = s['servico'] as Map<String, dynamic>?;
          final nomeServico = servicoData?['nome'] ?? 'Serviço sem nome';

          pendentes.add({
            ...s,
            'nome_servico': nomeServico,
            'chamado': chamado,
          });
        }
      }
    }

    if (widget.filialId != null) {
      pendentes.removeWhere((p) {
        final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == p['chamado'].obraId);
        return obra?.filialId != widget.filialId;
      });
    }

    final Map<String, List<Map<String, dynamic>>> porObra = {};
    for (var p in pendentes) {
      final obraId = p['chamado'].obraId;
      porObra.putIfAbsent(obraId, () => []).add(p);
    }

    if (pendentes.isEmpty) {
      return const Center(child: Text("Nenhuma pendência encontrada", style: TextStyle(fontSize: 16)));
    }

    return RefreshIndicator(
      onRefresh: _atualizarPendentes,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: porObra.length,
        itemBuilder: (context, index) {
          final obraId = porObra.keys.elementAt(index);
          final lista = porObra[obraId]!;
          final obra = obraProvider.obras.firstWhereOrNull((o) => o.id == obraId);

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              leading: const Icon(Icons.business, color: Colors.indigo, size: 28),
              title: Text(obra?.nome ?? 'Obra desconhecida'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(obraProvider.getClienteNome(obra?.clienteId)),
                  if (obra?.faseAtualNome != null)
                    Text("Fase: ${obra!.faseAtualNome}", style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text("${lista.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.grey[100],
                  ),
                ],
              ),
              children: lista.map((item) {
                final dataPend = item['data_atendimento'] != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['data_atendimento'].toString()))
                    : 'Sem data';

                final List<dynamic> fotosPendencia = item['foto_pendencia'] is List ? item['foto_pendencia'] : [];
                final hasPhotos = fotosPendencia.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nome_servico'] ?? 'Serviço',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5),
                      ),
                      const SizedBox(height: 6),
                      Text("Técnico: ${item['tecnico_nome'] ?? 'Não atribuído'}"),
                      Text("Desde: $dataPend"),

                      if (item['pendencia_descricao'] != null && item['pendencia_descricao'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "Pendência: ${item['pendencia_descricao']}",
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),

                      if (hasPhotos)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.photo_library, size: 18, color: Colors.blueGrey),
                              SizedBox(width: 6),
                              Text("Fotos da pendência disponíveis", style: TextStyle(color: Colors.blueGrey)),
                            ],
                          ),
                        ),

                      const Divider(height: 20),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}