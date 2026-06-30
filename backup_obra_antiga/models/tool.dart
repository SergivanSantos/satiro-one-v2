// lib/models/tool.dart
class Tool {
  final int? id;
  final String nome;
  final String? marca;
  final String? modelo;
  final String categoria; // ex: "Multímetro", "Furadeira", "Osciloscópio"
  final String? numeroSerie;
  final double? custo;
  final String estado; // 'novo', 'usado', 'danificado', 'perdido'
  final String tipo; // 'pessoal' ou 'compartilhada'
  final int? idTecnico; // NULL se compartilhada ou disponível
  final DateTime? dataRetirada;
  final DateTime? dataDevolucao;
  final String? observacaoPerda; // motivo da perda (se estado = perdido)

  Tool({
    this.id,
    required this.nome,
    this.marca,
    this.modelo,
    required this.categoria,
    this.numeroSerie,
    this.custo,
    this.estado = 'novo',
    required this.tipo,
    this.idTecnico,
    this.dataRetirada,
    this.dataDevolucao,
    this.observacaoPerda,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'marca': marca,
      'modelo': modelo,
      'categoria': categoria,
      'numero_serie': numeroSerie,
      'custo': custo,
      'estado': estado,
      'tipo': tipo,
      'id_tecnico': idTecnico,
      'data_retirada': dataRetirada?.toIso8601String(),
      'data_devolucao': dataDevolucao?.toIso8601String(),
      'observacao_perda': observacaoPerda,
    };
  }

  factory Tool.fromMap(Map<String, dynamic> map) {
    return Tool(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      marca: map['marca'] as String?,
      modelo: map['modelo'] as String?,
      categoria: map['categoria'] as String,
      numeroSerie: map['numero_serie'] as String?,
      custo: map['custo'] as double?,
      estado: map['estado'] as String? ?? 'novo',
      tipo: map['tipo'] as String,
      idTecnico: map['id_tecnico'] as int?,
      dataRetirada: map['data_retirada'] != null ? DateTime.parse(map['data_retirada']) : null,
      dataDevolucao: map['data_devolucao'] != null ? DateTime.parse(map['data_devolucao']) : null,
      observacaoPerda: map['observacao_perda'] as String?,
    );
  }

  Tool copyWith({
    int? id,
    String? nome,
    String? marca,
    String? modelo,
    String? categoria,
    String? numeroSerie,
    double? custo,
    String? estado,
    String? tipo,
    int? idTecnico,
    DateTime? dataRetirada,
    DateTime? dataDevolucao,
    String? observacaoPerda,
  }) {
    return Tool(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      categoria: categoria ?? this.categoria,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      custo: custo ?? this.custo,
      estado: estado ?? this.estado,
      tipo: tipo ?? this.tipo,
      idTecnico: idTecnico ?? this.idTecnico,
      dataRetirada: dataRetirada ?? this.dataRetirada,
      dataDevolucao: dataDevolucao ?? this.dataDevolucao,
      observacaoPerda: observacaoPerda ?? this.observacaoPerda,
    );
  }
}