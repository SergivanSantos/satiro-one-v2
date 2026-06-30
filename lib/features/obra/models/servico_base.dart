// lib/features/obra/models/servico_base.dart
class ServicoBase {
  final String id;
  final String sistemaId;
  final String? faseId;
  final String nome;
  final String? descricao;
  final String unidade;
  final double quantidadePadrao;
  final bool ativo;

  ServicoBase({
    required this.id,
    required this.sistemaId,
    this.faseId,
    required this.nome,
    this.descricao,
    this.unidade = 'un',
    this.quantidadePadrao = 1.0,
    this.ativo = true,
  });

  factory ServicoBase.fromMap(Map<String, dynamic> map) {
    return ServicoBase(
      id: map['id'] ?? '',
      sistemaId: map['sistema_id'] ?? '',
      faseId: map['fase_id'],
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      unidade: map['unidade'] ?? 'un',
      quantidadePadrao: (map['quantidade_padrao'] ?? 1.0).toDouble(),
      ativo: map['ativo'] ?? true,
    );
  }
}