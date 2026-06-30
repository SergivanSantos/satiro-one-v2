// lib/features/pop/models/pop.dart
class Pop {
  final String id;
  final String titulo;
  final String? codigo;
  final String categoriaPop;        // ← Renomeado
  final String? descricao;
  final String? arquivoUrl;
  final String versao;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Pop({
    required this.id,
    required this.titulo,
    this.codigo,
    required this.categoriaPop,
    this.descricao,
    this.arquivoUrl,
    this.versao = '1.0',
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Pop.fromJson(Map<String, dynamic> json) {
    return Pop(
      id: json['id'],
      titulo: json['titulo'],
      codigo: json['codigo'],
      categoriaPop: json['categoria_pop'] ?? '',   // ← Alterado
      descricao: json['descricao'],
      arquivoUrl: json['arquivo_url'],
      versao: json['versao'] ?? '1.0',
      ativo: json['ativo'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'codigo': codigo,
      'categoria_pop': categoriaPop,   // ← Alterado
      'descricao': descricao,
      'arquivo_url': arquivoUrl,
      'versao': versao,
      'ativo': ativo,
    };
  }
}