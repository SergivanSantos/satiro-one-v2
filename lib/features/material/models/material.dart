// lib/features/material/models/material.dart
class MaterialItem {
  final String id;
  final String nome;
  final String? codigo;
  final String unidade;
  final double precoMedio;
  final String? marcaId;
  final String? modeloId;
  final List<String> fasesUsoIds;
  final String? observacoes;
  final bool ativo;

  MaterialItem({
    required this.id,
    required this.nome,
    this.codigo,
    required this.unidade,
    this.precoMedio = 0.0,
    this.marcaId,
    this.modeloId,
    this.fasesUsoIds = const [],
    this.observacoes,
    this.ativo = true,
  });

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    return MaterialItem(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      codigo: map['codigo'],
      unidade: map['unidade'] ?? 'un',
      precoMedio: (map['preco_medio'] ?? 0.0).toDouble(),
      marcaId: map['marca_id'],
      modeloId: map['modelo_id'],
      fasesUsoIds: List<String>.from(map['fases_uso_ids'] ?? []),
      observacoes: map['observacoes'],
      ativo: map['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,           // ← Adicione isso
      'nome': nome,
      'codigo': codigo,
      'unidade': unidade,
      'preco_medio': precoMedio,
      'marca_id': marcaId,
      'modelo_id': modeloId,
      'fases_uso_ids': fasesUsoIds.isNotEmpty ? fasesUsoIds : [], // melhor que null
      'observacoes': observacoes,
      'ativo': ativo,
    };
  }

  @override
  String toString() {
    return 'MaterialItem(id: $id, nome: $nome, marcaId: $marcaId, modeloId: $modeloId)';
  }
}