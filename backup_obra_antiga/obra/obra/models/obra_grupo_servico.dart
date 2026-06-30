// lib/features/obra/models/obra_grupo_servico.dart
class ObraGrupoServico {
  final String id;
  final String ambienteId;
  final String nome;
  final String? descricao;
  final int ordem;
  final DateTime? createdAt;

  ObraGrupoServico({
    required this.id,
    required this.ambienteId,
    required this.nome,
    this.descricao,
    this.ordem = 0,
    this.createdAt,
  });

  factory ObraGrupoServico.fromMap(Map<String, dynamic> map) {
    return ObraGrupoServico(
      id: map['id'],
      ambienteId: map['ambiente_id'],
      nome: map['nome'] ?? 'Sem nome',
      descricao: map['descricao'],
      ordem: map['ordem'] ?? 0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}