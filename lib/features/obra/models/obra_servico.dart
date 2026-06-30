// lib/features/obra/models/obra_servico.dart
class ObraServico {
  final String id;
  final String obraId;
  final String ambienteId;
  final String? servicoBaseId;
  final String nome;
  final String? descricao;
  final String? faseId;
  final String? faseNome;
  final double quantidadeContratada;
  final String status;

  ObraServico({
    required this.id,
    required this.obraId,
    required this.ambienteId,
    this.servicoBaseId,
    required this.nome,
    this.descricao,
    this.faseId,
    this.faseNome,
    required this.quantidadeContratada,
    this.status = 'nao_iniciado',
  });

  factory ObraServico.fromMap(Map<String, dynamic> map) {
    final faseData = map['fase'] as Map<String, dynamic>?;

    return ObraServico(
      id: map['id'] ?? '',
      obraId: map['obra_id'] ?? '',
      ambienteId: map['ambiente_id'] ?? '',
      servicoBaseId: map['servico_base_id'],
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      faseId: map['fase_id'],
      faseNome: faseData?['nome']?.toString() ?? map['fase']?.toString(),
      quantidadeContratada: (map['quantidade_contratada'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'nao_iniciado',
    );
  }
}