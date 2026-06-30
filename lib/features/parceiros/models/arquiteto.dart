class Arquiteto {
  final String id;
  final String nome;
  final String? creaa;
  final String? telefone;
  final String? email;
  final String? endereco;
  final String? cidade;
  final DateTime? dataAniversario;
  final String? observacoes;
  final int? totalObras;           // ← Adicionado
  final DateTime dataCadastro;
  final bool ativo;

  Arquiteto({
    required this.id,
    required this.nome,
    this.creaa,
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

  factory Arquiteto.fromJson(Map<String, dynamic> json) {
    return Arquiteto(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      creaa: json['creaa'],
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
      'creaa': creaa,
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