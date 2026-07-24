// lib/features/material/models/obra_material.dart

class ObraMaterial {
  final String id;
  final String obraId;
  final String materialId;

  // Dados denormalizados (para performance na lista)
  final String materialNome;
  final String unidade;
  final double quantidade;

  // Status
  final String status; // 'a_comprar' | 'separado' | 'em_cotacao' | 'comprado' | 'em_transito' | 'entregue' | 'cancelado' | 'devolvido'

  // Informações de compra
  final String? numeroNf;
  final DateTime? dataCompra;
  final DateTime? dataPrevisaoEntrega;
  final String? fornecedor;
  final double? valorUnitario;
  final double? valorTotal;
  final String? observacaoCompras;

  // Entrega
  final DateTime? dataEntrega;
  final List<String> fotos;           // múltiplas fotos
  final String? assinaturaUrl;
  final String? entreguePara;
  final String? observacaoEntrega;

  // Controle
  final String? usuarioComprasId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ObraMaterial({
    required this.id,
    required this.obraId,
    required this.materialId,
    required this.materialNome,
    required this.unidade,
    required this.quantidade,
    required this.status,
    this.numeroNf,
    this.dataCompra,
    this.dataPrevisaoEntrega,
    this.fornecedor,
    this.valorUnitario,
    this.valorTotal,
    this.observacaoCompras,
    this.dataEntrega,
    this.fotos = const [],
    this.assinaturaUrl,
    this.entreguePara,
    this.observacaoEntrega,
    this.usuarioComprasId,
    this.createdAt,
    this.updatedAt,
  });

  // Status amigáveis
  static const Map<String, String> statusLabels = {
    'a_comprar': 'A Comprar',
    'separado': 'Separado (Estoque)',
    'em_cotacao': 'Em Cotação',
    'comprado': 'Comprado',
    'em_transito': 'Em Trânsito',
    'entregue': 'Entregue',
    'cancelado': 'Cancelado',
    'devolvido': 'Devolvido',
  };

  String get statusLabel => statusLabels[status] ?? status;

  bool get temFotos => fotos.isNotEmpty;
  bool get isFinal => ['entregue', 'cancelado', 'devolvido'].contains(status);

  factory ObraMaterial.fromMap(Map<String, dynamic> map) {
    return ObraMaterial(
      id: map['id']?.toString() ?? '',
      obraId: map['obra_id']?.toString() ?? '',
      materialId: map['material_id']?.toString() ?? '',
      materialNome: map['material']?['nome']?.toString() ??
          map['material_nome']?.toString() ??
          '',
      unidade: map['material']?['unidade']?.toString() ??
          map['unidade']?.toString() ??
          'un',
      quantidade: (map['quantidade'] as num?)?.toDouble() ?? 1.0,
      status: map['status']?.toString() ?? 'a_comprar',
      numeroNf: map['numero_nf']?.toString(),
      dataCompra: map['data_compra'] != null
          ? DateTime.tryParse(map['data_compra'].toString())
          : null,
      dataPrevisaoEntrega: map['data_previsao_entrega'] != null
          ? DateTime.tryParse(map['data_previsao_entrega'].toString())
          : null,
      fornecedor: map['fornecedor']?.toString(),
      valorUnitario: (map['valor_unitario'] as num?)?.toDouble(),
      valorTotal: (map['valor_total'] as num?)?.toDouble(),
      observacaoCompras: map['observacao_compras']?.toString(),
      dataEntrega: map['data_entrega'] != null
          ? DateTime.tryParse(map['data_entrega'].toString())
          : null,
      fotos: (map['fotos'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      assinaturaUrl: map['assinatura_url']?.toString(),
      entreguePara: map['entregue_para']?.toString(),
      observacaoEntrega: map['observacao_entrega']?.toString(),
      usuarioComprasId: map['usuario_compras_id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'obra_id': obraId,
      'material_id': materialId,
      'quantidade': quantidade,
      'status': status,
      'numero_nf': numeroNf,
      'data_compra': dataCompra?.toIso8601String(),
      'data_previsao_entrega': dataPrevisaoEntrega?.toIso8601String(),
      'fornecedor': fornecedor,
      'valor_unitario': valorUnitario,
      'valor_total': valorTotal,
      'observacao_compras': observacaoCompras,
      'data_entrega': dataEntrega?.toIso8601String(),
      'fotos': fotos,
      'assinatura_url': assinaturaUrl,
      'entregue_para': entreguePara,
      'observacao_entrega': observacaoEntrega,
      'usuario_compras_id': usuarioComprasId,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  ObraMaterial copyWith({
    String? status,
    String? numeroNf,
    DateTime? dataCompra,
    DateTime? dataPrevisaoEntrega,
    String? fornecedor,
    double? valorUnitario,
    double? valorTotal,
    String? observacaoCompras,
    DateTime? dataEntrega,
    List<String>? fotos,
    String? assinaturaUrl,
    String? entreguePara,
    String? observacaoEntrega,
    String? usuarioComprasId,
  }) {
    return ObraMaterial(
      id: id,
      obraId: obraId,
      materialId: materialId,
      materialNome: materialNome,
      unidade: unidade,
      quantidade: quantidade,
      status: status ?? this.status,
      numeroNf: numeroNf ?? this.numeroNf,
      dataCompra: dataCompra ?? this.dataCompra,
      dataPrevisaoEntrega: dataPrevisaoEntrega ?? this.dataPrevisaoEntrega,
      fornecedor: fornecedor ?? this.fornecedor,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      valorTotal: valorTotal ?? this.valorTotal,
      observacaoCompras: observacaoCompras ?? this.observacaoCompras,
      dataEntrega: dataEntrega ?? this.dataEntrega,
      fotos: fotos ?? this.fotos,
      assinaturaUrl: assinaturaUrl ?? this.assinaturaUrl,
      entreguePara: entreguePara ?? this.entreguePara,
      observacaoEntrega: observacaoEntrega ?? this.observacaoEntrega,
      usuarioComprasId: usuarioComprasId ?? this.usuarioComprasId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}