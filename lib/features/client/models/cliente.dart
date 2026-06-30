class Cliente {
  final String id;
  final String nome;
  final String? cpfCnpj;
  final String? tipo;
  final String? razaoSocial;
  final String? nomeFantasia;

  final String? endereco;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? cep;

  final String? telefone;
  final String? celular;
  final String? email;
  final String? observacoes;

  final int totalObras;
  final int obrasAtivas;

  // Nova propriedade: Lista de IDs das filiais vinculadas
  final List<String> filiaisIds;

  Cliente({
    required this.id,
    required this.nome,
    this.cpfCnpj,
    this.tipo,
    this.razaoSocial,
    this.nomeFantasia,
    this.endereco,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
    this.telefone,
    this.celular,
    this.email,
    this.observacoes,
    this.totalObras = 0,
    this.obrasAtivas = 0,
    this.filiaisIds = const [],
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      cpfCnpj: json['cpf_cnpj'],
      tipo: json['tipo'],
      razaoSocial: json['razao_social'],
      nomeFantasia: json['nome_fantasia'],
      endereco: json['endereco'],
      numero: json['numero'],
      complemento: json['complemento'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      estado: json['estado'],
      cep: json['cep'],
      telefone: json['telefone'],
      celular: json['celular'],
      email: json['email'],
      observacoes: json['observacoes'],
      totalObras: json['total_obras'] ?? 0,
      obrasAtivas: json['obras_ativas'] ?? 0,
      filiaisIds: json['filiais_ids'] != null
          ? List<String>.from(json['filiais_ids'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cpf_cnpj': cpfCnpj,
      'tipo': tipo,
      'razao_social': razaoSocial,
      'nome_fantasia': nomeFantasia,
      'endereco': endereco,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'telefone': telefone,
      'celular': celular,
      'email': email,
      'observacoes': observacoes,
      'total_obras': totalObras,
      'obras_ativas': obrasAtivas,
    };
  }
}