// lib/features/fase/models/fase.dart
class Fase {
  final String id;
  final String nome;
  final String? descricao;
  final int ordem;
  final bool ativo;
  final bool exigeChecklist;
  final String? checklistNome;
  final bool exigeOrdemServico;   // ← Novo campo

  Fase({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ordem,
    this.ativo = true,
    this.exigeChecklist = false,
    this.checklistNome,
    this.exigeOrdemServico = false,   // ← Novo
  });

  factory Fase.fromMap(Map<String, dynamic> map) {
    return Fase(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      ordem: map['ordem'] ?? 0,
      ativo: map['ativo'] ?? true,
      exigeChecklist: map['exige_checklist'] ?? false,
      checklistNome: map['checklist_nome'],
      exigeOrdemServico: map['exige_ordem_servico'] ?? false,   // ← Novo
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'ordem': ordem,
      'ativo': ativo,
      'exige_checklist': exigeChecklist,
      'checklist_nome': checklistNome,
      'exige_ordem_servico': exigeOrdemServico,   // ← Novo
    };
  }
}