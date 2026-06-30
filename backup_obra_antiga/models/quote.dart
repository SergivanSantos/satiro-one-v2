// lib/models/quote.dart
import 'quote_item.dart';

class Quote {
  final int? id;
  final String? codigo;
  final DateTime? validade;
  final int clienteId;
  final String clienteNome;
  final DateTime data;
  final List<QuoteItem> itens;
  final double desconto;
  final String status;
  final String? observacoes;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final int versao;

  Quote({
    this.id,
    this.codigo,
    this.validade,
    required this.clienteId,
    required this.clienteNome,
    required this.data,
    List<QuoteItem>? itens,
    this.desconto = 0.0,
    this.status = 'aberto',
    this.observacoes,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    this.versao = 1,
  })  : itens = itens ?? [],
        criadoEm = criadoEm ?? DateTime.now(),
        atualizadoEm = atualizadoEm ?? DateTime.now();

  // GETTERS CORRETOS (sem parâmetros)
  double get subtotal => itens.fold(0.0, (sum, item) => sum + item.totalNoAmbiente);

  double get total => (subtotal - desconto).clamp(0.0, double.infinity);

  // MÉTODO (com parâmetro) — agora correto
  double totalPorAmbiente(String ambiente) {
    return itens
        .where((i) => (i.ambiente ?? 'Global') == ambiente)
        .fold(0.0, (sum, i) => sum + i.totalNoAmbiente);
  }

  // MÉTODO para pegar todos os ambientes usados
  Set<String> get ambientesUsados {
    final Set<String> amb = {'Global'};
    for (var item in itens) {
      if (item.ambiente != null && item.ambiente!.isNotEmpty) {
        amb.add(item.ambiente!);
      }
    }
    return amb;
  }

  Quote copyWith({
    int? id,
    String? codigo,
    DateTime? validade,
    int? clienteId,
    String? clienteNome,
    DateTime? data,
    List<QuoteItem>? itens,
    double? desconto,
    String? status,
    String? observacoes,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    int? versao,
  }) {
    return Quote(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      validade: validade ?? this.validade,
      clienteId: clienteId ?? this.clienteId,
      clienteNome: clienteNome ?? this.clienteNome,
      data: data ?? this.data,
      itens: itens ?? this.itens,
      desconto: desconto ?? this.desconto,
      status: status ?? this.status,
      observacoes: observacoes ?? this.observacoes,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? DateTime.now(),
      versao: versao ?? this.versao + 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'validade': validade?.toIso8601String(),
      'cliente_id': clienteId,
      'cliente_nome': clienteNome,
      'data': data.toIso8601String(),
      'desconto': desconto,
      'status': status,
      'observacoes': observacoes,
      'criado_em': criadoEm?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
      'versao': versao,
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as int?,
      codigo: map['codigo'] as String?,
      validade: map['validade'] != null ? DateTime.parse(map['validade']) : null,
      clienteId: map['cliente_id'] as int,
      clienteNome: map['cliente_nome'] as String,
      data: DateTime.parse(map['data'] as String),
      desconto: (map['desconto'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'aberto',
      observacoes: map['observacoes'] as String?,
      criadoEm: map['criado_em'] != null ? DateTime.parse(map['criado_em']) : null,
      atualizadoEm: map['atualizado_em'] != null ? DateTime.parse(map['atualizado_em']) : null,
      versao: map['versao'] as int? ?? 1,
      itens: [], // carregado separadamente
    );
  }

  @override
  String toString() => 'Quote $codigo - $clienteNome - R\$${total.toStringAsFixed(2)}';
}