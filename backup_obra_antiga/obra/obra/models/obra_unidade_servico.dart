// lib/features/obra/models/obra_unidade_servico.dart
class ObraUnidadeServico {
  final String id;
  final String ambienteId;
  final String? grupoServicoId;   // ← Importante
  final String nome;
  final String? descricao;
  final double quantidadeContratada;
  final double? quantidadeExecutada;
  final String status;

  ObraUnidadeServico({
    required this.id,
    required this.ambienteId,
    this.grupoServicoId,
    required this.nome,
    this.descricao,
    this.quantidadeContratada = 0,
    this.quantidadeExecutada,
    this.status = 'nao_iniciado',
  });

  factory ObraUnidadeServico.fromMap(Map<String, dynamic> map) {
    return ObraUnidadeServico(
      id: map['id'],
      ambienteId: map['ambiente_id'],
      grupoServicoId: map['grupo_servico_id'],
      nome: map['nome'] ?? 'Sem nome',
      descricao: map['descricao'],
      quantidadeContratada: (map['quantidade_contratada'] ?? 0).toDouble(),
      quantidadeExecutada: map['quantidade_executada']?.toDouble(),
      status: map['status'] ?? 'nao_iniciado',
    );
  }
}