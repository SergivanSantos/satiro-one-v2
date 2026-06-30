// lib/features/obra/models/servico.dart
class Servico {
  final String id;
  final String blocoId;
  final String descricao;
  final int quantidade;
  final String? unidade;
  final double valorUnitarioOrcado;
  final double valorTotalOrcado;
  final String? observacoes;

  Servico({
    required this.id,
    required this.blocoId,
    required this.descricao,
    this.quantidade = 1,
    this.unidade,
    this.valorUnitarioOrcado = 0.0,
    this.valorTotalOrcado = 0.0,
    this.observacoes,
  });

  factory Servico.fromMap(Map<String, dynamic> map) {
    return Servico(
      id: map['id'],
      blocoId: map['bloco_id'],
      descricao: map['descricao'],
      quantidade: map['quantidade'] ?? 1,
      unidade: map['unidade'],
      valorUnitarioOrcado: (map['valor_unitario_orcado'] ?? 0.0).toDouble(),
      valorTotalOrcado: (map['valor_total_orcado'] ?? 0.0).toDouble(),
      observacoes: map['observacoes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bloco_id': blocoId,
      'descricao': descricao,
      'quantidade': quantidade,
      'unidade': unidade,
      'valor_unitario_orcado': valorUnitarioOrcado,
      'observacoes': observacoes,
    };
  }
}