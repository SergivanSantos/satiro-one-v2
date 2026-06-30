// lib/features/servicos/models/servico.dart
class Servico {
  final String id;
  final String nome;
  final String? descricao;
  final double? valor;
  final String? categoria;        // Nome vindo do join
  final String? categoriaId;
  final bool ativo;

  final String? popId;
  final String? popTitulo;
  final String? popUrl;

  Servico({
    required this.id,
    required this.nome,
    this.descricao,
    this.valor,
    this.categoria,
    this.categoriaId,
    this.ativo = true,
    this.popId,
    this.popTitulo,
    this.popUrl,
  });

  factory Servico.fromMap(Map<String, dynamic> map) {
    final popData = map['pop'] as Map<String, dynamic>?;
    final categoriaData = map['categoria'] as Map<String, dynamic>?;

    return Servico(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      descricao: map['descricao']?.toString(),
      valor: map['valor'] != null ? (map['valor'] as num).toDouble() : null,

      categoria: categoriaData?['nome']?.toString(),
      categoriaId: map['categoria_id']?.toString() ?? categoriaData?['id']?.toString(),

      ativo: map['ativo'] ?? true,
      popId: map['pop_id']?.toString() ?? popData?['id']?.toString(),
      popTitulo: popData?['titulo']?.toString(),
      popUrl: popData?['arquivo_url']?.toString(),
    );
  }

  bool get temPop => popId != null && popId!.isNotEmpty;
  String get popNomeDisplay => popTitulo ?? 'Sem POP';

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'valor': valor,
      'categoria_id': categoriaId,
      'ativo': ativo,
      'pop_id': popId,
    };
  }
}