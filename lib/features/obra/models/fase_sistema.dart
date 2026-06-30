// lib/features/obra/models/fase_sistema.dart
class FaseSistema {
  final String id;
  final String sistemaId;
  final String nome;
  final String? descricao;
  final int ordem;
  final String? cor;

  FaseSistema({
    required this.id,
    required this.sistemaId,
    required this.nome,
    this.descricao,
    this.ordem = 0,
    this.cor,
  });

  factory FaseSistema.fromMap(Map<String, dynamic> map) {
    return FaseSistema(
      id: map['id'] ?? '',
      sistemaId: map['sistema_id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      ordem: map['ordem'] ?? 0,
      cor: map['cor'],
    );
  }
}