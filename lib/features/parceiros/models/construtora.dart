class Construtora {
  final String id;
  final String nome;
  final String? cnpj;
  final String? telefone;
  final String? email;
  final String? endereco;
  final String? cidade;
  final DateTime? dataAniversario;
  final String? observacoes;
  final int? totalObras;           // Mantido (caso queira usar)
  final DateTime dataCadastro;
  final bool ativo;

  Construtora({
    required this.id,
    required this.nome,
    this.cnpj,
    this.telefone,
    this.email,
    this.endereco,
    this.cidade,
    this.dataAniversario,
    this.observacoes,
    this.totalObras,
    DateTime? dataCadastro,
    this.ativo = true,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  factory Construtora.fromJson(Map<String, dynamic> json) {
    return Construtora(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      cnpj: json['cnpj'],
      telefone: json['telefone'],
      email: json['email'],
      endereco: json['endereco'],
      cidade: json['cidade'],
      dataAniversario: json['data_aniversario'] != null ? DateTime.parse(json['data_aniversario']) : null,
      observacoes: json['observacoes'],
      totalObras: json['total_obras'],
      dataCadastro: DateTime.parse(json['data_cadastro'] ?? DateTime.now().toIso8601String()),
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cnpj': cnpj,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
      'cidade': cidade,
      'data_aniversario': dataAniversario?.toIso8601String(),
      'observacoes': observacoes,
      'total_obras': totalObras,
      'ativo': ativo,
    };
  }
}