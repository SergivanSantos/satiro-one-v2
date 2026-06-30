// lib/features/obra/screens/obra_visual_matrix_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/obra_estrutura_provider.dart';
import '../models/obra_bloco.dart';
import '../models/obra_piso.dart';
import '../models/obra_unidade.dart';
import '../models/obra_ambiente.dart';

class ObraVisualMatrixScreen extends StatelessWidget {
  final String obraId;
  final String obraNome;

  const ObraVisualMatrixScreen({
    super.key,
    required this.obraId,
    required this.obraNome,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ObraEstruturaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Visão Geral da Obra - $obraNome'),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: provider.blocos.map((bloco) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Text(
                    bloco.nome.toUpperCase(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),

                ...bloco.pisos.map((piso) => _buildPisoCard(context, piso)),

                if (bloco.ambientesDiretos.isNotEmpty)
                  _buildDirectAmbientesSection(context, bloco.ambientesDiretos),

                const Divider(height: 30),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==================== CARDS ====================
  Widget _buildPisoCard(BuildContext context, ObraPiso piso) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(piso.nome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: piso.unidades.map((unidade) => _buildUnidadeCard(context, unidade)).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUnidadeCard(BuildContext context, ObraUnidade unidade) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(unidade.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...unidade.ambientes.map((ambiente) => _buildAmbienteCompact(context, ambiente)),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectAmbientesSection(BuildContext context, List<ObraAmbiente> ambientes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text("Ambientes Diretos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        Column(
          children: ambientes.map((amb) => _buildAmbienteCompact(context, amb)).toList(),
        ),
      ],
    );
  }

  Widget _buildAmbienteCompact(BuildContext context, ObraAmbiente ambiente) {
    final total = ambiente.servicos.length;
    final concluidos = ambiente.servicos.where((s) => s.status == 'concluido').length;
    final percent = total > 0 ? (concluidos / total * 100).round() : 0;

    final cor = percent >= 80 ? Colors.green : percent >= 50 ? Colors.orange : Colors.redAccent;

    return GestureDetector(
      onTap: () => _showServicesDialog(context, ambiente),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(ambiente.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                Text('$percent%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cor)),
                const SizedBox(width: 6),
                Text('$concluidos/$total', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
              ],
            ),

            if (ambiente.grupos.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...ambiente.grupos.map((grupo) {
                final qtd = ambiente.servicos.where((s) => s.grupoServicoId == grupo.id).length;
                return Padding(
                  padding: const EdgeInsets.only(left: 4, top: 1),
                  child: Row(
                    children: [
                      const Icon(Icons.folder, size: 15, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(child: Text(grupo.nome, style: const TextStyle(fontSize: 13))),
                      if (qtd > 0) Text(' ($qtd)', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== POP-UP ====================
  // ==================== POP-UP ORGANIZADO POR GRUPOS ====================
  void _showServicesDialog(BuildContext buildContext, ObraAmbiente ambiente) {
    showDialog(
      context: buildContext,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(ambiente.nome),
        content: SizedBox(
          width: double.maxFinite,
          height: 520,
          child: ListView(
            children: [
              // ==================== GRUPOS ====================
              if (ambiente.grupos.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, top: 4),
                  child: Text('Grupos de Serviço', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...ambiente.grupos.map((grupo) {
                  final servicosDoGrupo = ambiente.servicos
                      .where((s) => s.grupoServicoId == grupo.id)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Colors.amber.shade50,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.folder, color: Colors.amber),
                          title: Text(grupo.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${servicosDoGrupo.length} serviços'),
                        ),
                      ),
                      // Serviços dentro deste grupo
                      ...servicosDoGrupo.map((s) => ListTile(
                        leading: Icon(
                          s.status == 'concluido' ? Icons.check_circle : Icons.pending,
                          color: s.status == 'concluido' ? Colors.green : Colors.orange,
                        ),
                        title: Text(s.nome),
                        subtitle: Text(s.descricao ?? 'Sem descrição'),
                        trailing: Text('${s.quantidadeContratada.toInt()}'),
                        contentPadding: const EdgeInsets.only(left: 60, right: 16),
                      )),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
              ],

              // ==================== SERVIÇOS INDIVIDUAIS (sem grupo) ====================
              if (ambiente.servicos.any((s) => s.grupoServicoId == null)) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, top: 12),
                  child: Text('Serviços Individuais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...ambiente.servicos
                    .where((s) => s.grupoServicoId == null)
                    .map((s) => ListTile(
                  leading: Icon(
                    s.status == 'concluido' ? Icons.check_circle : Icons.pending,
                    color: s.status == 'concluido' ? Colors.green : Colors.orange,
                  ),
                  title: Text(s.nome),
                  subtitle: Text(s.descricao ?? 'Sem descrição'),
                  trailing: Text('${s.quantidadeContratada.toInt()}'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}