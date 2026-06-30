// lib/features/obra/models/wizard_acao.dart
class WizardAcao {
  final String id;
  final String perguntaId;
  final String acaoTipo; // criar_servico, adicionar_item, definir_quantidade
  final String? servicoBaseId;
  final String? itemId;
  final String? quantidadeFormula;
  final String? faseId;

  WizardAcao({
    required this.id,
    required this.perguntaId,
    required this.acaoTipo,
    this.servicoBaseId,
    this.itemId,
    this.quantidadeFormula,
    this.faseId,
  });

  factory WizardAcao.fromMap(Map<String, dynamic> map) {
    return WizardAcao(
      id: map['id'] ?? '',
      perguntaId: map['pergunta_id'] ?? '',
      acaoTipo: map['acao_tipo'] ?? '',
      servicoBaseId: map['servico_base_id'],
      itemId: map['item_id'],
      quantidadeFormula: map['quantidade_formula'],
      faseId: map['fase_id'],
    );
  }
}