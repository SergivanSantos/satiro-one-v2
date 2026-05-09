// lib/models/tool_catalog.dart
class ToolCatalog {
  final int? id;
  final String nome;
  final String? marca;
  final String? modelo;
  final String categoria;
  final double? valorUnitario;
  final int quantidadeTotal;
  final String? photoPath;

  ToolCatalog({
    this.id,
    required this.nome,
    this.marca,
    this.modelo,
    required this.categoria,
    this.valorUnitario,
    required this.quantidadeTotal,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'marca': marca,
      'modelo': modelo,
      'categoria': categoria,
      'valor_unitario': valorUnitario,
      'quantidade_total': quantidadeTotal,
      'photo_path': photoPath,
    };
  }

  factory ToolCatalog.fromMap(Map<String, dynamic> map) {
    return ToolCatalog(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      marca: map['marca'] as String?,
      modelo: map['modelo'] as String?,
      categoria: map['categoria'] as String,
      valorUnitario: _parseDouble(map['valor_unitario']), // FUNÇÃO SEGURA
      quantidadeTotal: map['quantidade_total'] as int? ?? 0,
      photoPath: map['photo_path'] as String?,
    );
  }

  // FUNÇÃO AUXILIAR PARA CONVERTER int ou double → double?
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  ToolCatalog copyWith({
    int? id,
    String? nome,
    String? marca,
    String? modelo,
    String? categoria,
    double? valorUnitario,
    int? quantidadeTotal,
    String? photoPath,
  }) {
    return ToolCatalog(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      categoria: categoria ?? this.categoria,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      quantidadeTotal: quantidadeTotal ?? this.quantidadeTotal,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}