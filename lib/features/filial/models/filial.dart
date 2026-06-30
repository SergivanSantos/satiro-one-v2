class Filial {
  final String id;
  final String nome;
  final String? cidade;
  final String? estado;           // UF
  final String? observacoes;
  final bool ativa;
  final DateTime dataCadastro;

  Filial({
    required this.id,
    required this.nome,
    this.cidade,
    this.estado,
    this.observacoes,
    this.ativa = true,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  factory Filial.fromJson(Map<String, dynamic> json) {
    return Filial(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      cidade: json['cidade'],
      estado: json['estado'],
      observacoes: json['observacoes'],
      ativa: json['ativa'] ?? true,
      dataCadastro: DateTime.parse(json['data_cadastro'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cidade': cidade,
      'estado': estado,
      'observacoes': observacoes,
      'ativa': ativa,
    };
  }
}