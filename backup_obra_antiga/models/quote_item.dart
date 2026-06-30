// lib/models/quote_item.dart
class QuoteItem {
  final int? id;
  final int? equipamentoId;
  final String nomeEquipamento;
  final int quantidadeTotal;
  final double precoUnitario;
  String? ambiente;
  int quantidadeNoAmbiente;
  String? observacaoItem; // <--- NOVO CAMPO: "Caixas brancas em série"

  QuoteItem({
    this.id,
    this.equipamentoId,
    required this.nomeEquipamento,
    required this.quantidadeTotal,
    required this.precoUnitario,
    this.ambiente,
    int? quantidadeNoAmbiente,
    this.observacaoItem, // <--- novo
  }) : quantidadeNoAmbiente = quantidadeNoAmbiente ?? quantidadeTotal;

  double get totalNoAmbiente => precoUnitario * quantidadeNoAmbiente;
  int get quantidadeRestante => quantidadeTotal - quantidadeNoAmbiente;

  QuoteItem copyWith({
    int? id,
    String? ambiente,
    int? quantidadeNoAmbiente,
    String? observacaoItem,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      equipamentoId: equipamentoId,
      nomeEquipamento: nomeEquipamento,
      quantidadeTotal: quantidadeTotal,
      precoUnitario: precoUnitario,
      ambiente: ambiente ?? this.ambiente,
      quantidadeNoAmbiente: quantidadeNoAmbiente ?? this.quantidadeNoAmbiente,
      observacaoItem: observacaoItem ?? this.observacaoItem,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote_id': null, // será preenchido no provider
      'equipamento_id': equipamentoId,
      'nome_equipamento': nomeEquipamento,
      'quantidade_total': quantidadeTotal,
      'preco_unitario': precoUnitario,
      'ambiente': ambiente,
      'quantidade_no_ambiente': quantidadeNoAmbiente,
      'observacao_item': observacaoItem, // <--- nova coluna
    };
  }

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      id: map['id'] as int?,
      equipamentoId: map['equipamento_id'] as int?,
      nomeEquipamento: map['nome_equipamento'] as String,
      quantidadeTotal: map['quantidade_total'] as int,
      precoUnitario: (map['preco_unitario'] as num).toDouble(),
      ambiente: map['ambiente'] as String?,
      quantidadeNoAmbiente: map['quantidade_no_ambiente'] as int? ?? map['quantidade_total'] as int,
      observacaoItem: map['observacao_item'] as String?,
    );
  }

  @override
  String toString() {
    return '$quantidadeNoAmbiente/$quantidadeTotal $nomeEquipamento → ${ambiente ?? "Global"} ${observacaoItem != null ? "($observacaoItem)" : ""}';
  }
}