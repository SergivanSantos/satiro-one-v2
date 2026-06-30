// lib/features/obra/models/categoria.dart
class Categoria {
  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;

  Categoria({
    required this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
  });

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
    };
  }
}