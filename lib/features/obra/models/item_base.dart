// lib/features/obra/models/item_base.dart
class ItemBase {
  final String id;
  final String nome;
  final String? descricao;
  final String unidade;
  final String? categoria;
  final bool ativo;

  ItemBase({
    required this.id,
    required this.nome,
    this.descricao,
    this.unidade = 'un',
    this.categoria,
    this.ativo = true,
  });

  factory ItemBase.fromMap(Map<String, dynamic> map) {
    return ItemBase(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      unidade: map['unidade'] ?? 'un',
      categoria: map['categoria'],
      ativo: map['ativo'] ?? true,
    );
  }
}