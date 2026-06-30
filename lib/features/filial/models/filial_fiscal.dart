class FilialFiscal {
  final String id;
  final String filialId;
  final String razaoSocial;
  final String nomeFantasia;
  final String cnpj;
  final String? inscricaoEstadual;
  final String? inscricaoMunicipal;
  final String endereco;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;
  final String? telefone;
  final String? email;
  final String? observacoes;

  FilialFiscal({
    required this.id,
    required this.filialId,
    required this.razaoSocial,
    required this.nomeFantasia,
    required this.cnpj,
    this.inscricaoEstadual,
    this.inscricaoMunicipal,
    required this.endereco,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.cep,
    this.telefone,
    this.email,
    this.observacoes,
  });

  factory FilialFiscal.fromJson(Map<String, dynamic> json) {
    return FilialFiscal(
      id: json['id'] ?? '',
      filialId: json['filial_id'] ?? '',
      razaoSocial: json['razao_social'] ?? '',
      nomeFantasia: json['nome_fantasia'] ?? '',
      cnpj: json['cnpj'] ?? '',
      inscricaoEstadual: json['inscricao_estadual'],
      inscricaoMunicipal: json['inscricao_municipal'],
      endereco: json['endereco'] ?? '',
      numero: json['numero'] ?? '',
      complemento: json['complemento'],
      bairro: json['bairro'] ?? '',
      cidade: json['cidade'] ?? '',
      estado: json['estado'] ?? '',
      cep: json['cep'] ?? '',
      telefone: json['telefone'],
      email: json['email'],
      observacoes: json['observacoes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filial_id': filialId,
      'razao_social': razaoSocial,
      'nome_fantasia': nomeFantasia,
      'cnpj': cnpj,
      'inscricao_estadual': inscricaoEstadual,
      'inscricao_municipal': inscricaoMunicipal,
      'endereco': endereco,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'telefone': telefone,
      'email': email,
      'observacoes': observacoes,
    };
  }
}