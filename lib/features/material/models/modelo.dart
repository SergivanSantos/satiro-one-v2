// lib/features/material/models/modelo.dart
class Modelo {
  final String id;
  final String marcaId;
  final String nome;
  final bool ativo;

  Modelo({
    required this.id,
    required this.marcaId,
    required this.nome,
    this.ativo = true,
  });

  factory Modelo.fromMap(Map<String, dynamic> map) {
    return Modelo(
      id: map['id'] ?? '',
      marcaId: map['marca_id'] ?? '',
      nome: map['nome'] ?? '',
      ativo: map['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'marca_id': marcaId,
      'nome': nome,
      'ativo': ativo,
    };
  }
}