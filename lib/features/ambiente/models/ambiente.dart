// lib/features/ambiente/models/ambiente.dart
class Ambiente {
  final String id;
  final String nome;
  final int ordem;
  final bool ativo;
  final DateTime? createdAt;

  Ambiente({
    required this.id,
    required this.nome,
    required this.ordem,
    this.ativo = true,
    this.createdAt,
  });

  factory Ambiente.fromMap(Map<String, dynamic> map) {
    return Ambiente(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      ordem: map['ordem'] ?? 0,
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'ordem': ordem,
      'ativo': ativo,
    };
  }
}