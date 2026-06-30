// lib/features/obra/models/wizard_pergunta.dart
class WizardPergunta {
  final String id;
  final String sistemaId;
  final String titulo;
  final String tipo; // quantidade, multi_ambiente, sim_nao, select, etc.
  final int ordem;
  final bool obrigatorio;
  final String? dependeDe;
  final String? valorDependencia;
  final List<String>? opcoes;

  WizardPergunta({
    required this.id,
    required this.sistemaId,
    required this.titulo,
    required this.tipo,
    this.ordem = 0,
    this.obrigatorio = true,
    this.dependeDe,
    this.valorDependencia,
    this.opcoes,
  });

  factory WizardPergunta.fromMap(Map<String, dynamic> map) {
    return WizardPergunta(
      id: map['id'] ?? '',
      sistemaId: map['sistema_id'] ?? '',
      titulo: map['titulo'] ?? '',
      tipo: map['tipo'] ?? '',
      ordem: map['ordem'] ?? 0,
      obrigatorio: map['obrigatorio'] ?? true,
      dependeDe: map['depende_de'],
      valorDependencia: map['valor_dependencia'],
      opcoes: map['opcoes_json'] != null ? List<String>.from(map['opcoes_json']) : null,
    );
  }
}