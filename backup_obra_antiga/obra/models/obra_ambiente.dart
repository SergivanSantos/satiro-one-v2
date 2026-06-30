// lib/features/obra/models/obra_ambiente.dart
import 'obra_grupo_servico.dart';
import 'obra_unidade_servico.dart';

class ObraAmbiente {
  final String id;
  final String? unidadeId;
  final String? blocoId;        // para ambientes diretos
  final String nome;
  final int ordem;
  final List<ObraUnidadeServico> servicos = [];
  final List<ObraGrupoServico> grupos = [];   // ← adicionar isso

  ObraAmbiente({
    required this.id,
    this.unidadeId,
    this.blocoId,
    required this.nome,
    this.ordem = 0,
  });

  factory ObraAmbiente.fromMap(Map<String, dynamic> map) {
    return ObraAmbiente(
      id: map['id'],
      unidadeId: map['unidade_id'],
      blocoId: map['bloco_id'],
      nome: map['nome'] ?? 'Sem nome',
      ordem: map['ordem'] ?? 0,
    );
  }
}