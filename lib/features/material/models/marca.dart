// lib/features/material/models/marca.dart
class Marca {
  final String id;
  final String nome;
  final bool ativo;

  Marca({
    required this.id,
    required this.nome,
    this.ativo = true,
  });

  factory Marca.fromMap(Map<String, dynamic> map) {
    return Marca(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      ativo: map['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'ativo': ativo,
    };
  }
}