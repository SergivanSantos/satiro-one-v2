// lib/features/anotacoes/models/nota.dart
class Nota {
  final String id;
  final String titulo;
  final String conteudo;
  final String? categoria;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool favorito;

  Nota({
    required this.id,
    required this.titulo,
    required this.conteudo,
    this.categoria,
    required this.createdAt,
    required this.updatedAt,
    this.favorito = false,
  });

  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      id: json['id'],
      titulo: json['titulo'],
      conteudo: json['conteudo'],
      categoria: json['categoria'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      favorito: json['favorito'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'conteudo': conteudo,
      'categoria': categoria,
      'favorito': favorito,
    };
  }
}