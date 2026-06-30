// lib/models/quote_distribution.dart
import 'dart:convert'; // <--- IMPORT OBRIGATÓRIO

class QuoteDistribution {
  final int? id;
  final int quoteId;
  final DateTime criadoEm;
  final Map<String, List<DistributedItem>> ambientes;

  QuoteDistribution({
    this.id,
    required this.quoteId,
    required this.ambientes,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  factory QuoteDistribution.fromMap(Map<String, dynamic> map) {
    final jsonString = map['dados_json'] as String;
    final Map<String, dynamic> jsonMap = json.decode(jsonString); // <--- json.decode

    final ambientes = <String, List<DistributedItem>>{};
    jsonMap.forEach((key, value) {
      ambientes[key] = (value as List)
          .map((i) => DistributedItem.fromJson(i as Map<String, dynamic>))
          .toList();
    });

    return QuoteDistribution(
      id: map['id'] as int?,
      quoteId: map['quote_id'] as int,
      ambientes: ambientes,
      criadoEm: DateTime.parse(map['data_criacao'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final ambientesJson = ambientes.map((key, value) => MapEntry(
      key,
      value.map((i) => i.toJson()).toList(),
    ));

    return {
      'id': id,
      'quote_id': quoteId,
      'data_criacao': criadoEm.toIso8601String(),
      'dados_json': json.encode(ambientesJson), // <--- json.encode
    };
  }

  QuoteDistribution copyWith({
    int? id,
    Map<String, List<DistributedItem>>? ambientes,
  }) {
    return QuoteDistribution(
      id: id ?? this.id,
      quoteId: quoteId,
      ambientes: ambientes ?? this.ambientes,
      criadoEm: criadoEm,
    );
  }
}

class DistributedItem {
  final int equipamentoId;
  final String nomeEquipamento;
  final double precoUnitario;
  final int quantidade;
  final String? observacao;

  DistributedItem({
    required this.equipamentoId,
    required this.nomeEquipamento,
    required this.precoUnitario,
    required this.quantidade,
    this.observacao,
  });

  factory DistributedItem.fromJson(Map<String, dynamic> json) {
    return DistributedItem(
      equipamentoId: json['equipamentoId'] as int,
      nomeEquipamento: json['nomeEquipamento'] as String,
      precoUnitario: (json['precoUnitario'] as num).toDouble(),
      quantidade: json['quantidade'] as int,
      observacao: json['observacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'equipamentoId': equipamentoId,
      'nomeEquipamento': nomeEquipamento,
      'precoUnitario': precoUnitario,
      'quantidade': quantidade,
      'observacao': observacao,
    };
  }

  DistributedItem copyWith({
    int? quantidade,
    String? observacao,
  }) {
    return DistributedItem(
      equipamentoId: equipamentoId,
      nomeEquipamento: nomeEquipamento,
      precoUnitario: precoUnitario,
      quantidade: quantidade ?? this.quantidade,
      observacao: observacao ?? this.observacao,
    );
  }
}