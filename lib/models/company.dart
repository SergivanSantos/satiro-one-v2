class Company {
  final int id;
  final String name;           // Nome fantasia
  final String corporateName;  // Razão social
  final String cnpj;
  final String cep;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String phone;
  final String email;
  final String? logoPath;
  final bool isDefault;

  Company({
    required this.id,
    required this.name,
    required this.corporateName,
    required this.cnpj,
    required this.cep,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.phone,
    required this.email,
    this.logoPath,
    this.isDefault = false,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'],
      name: map['name'],
      corporateName: map['corporate_name'],
      cnpj: map['cnpj'],
      cep: map['cep'] ?? '',
      street: map['street'] ?? '',
      number: map['number'] ?? '',
      complement: map['complement'],
      neighborhood: map['neighborhood'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      logoPath: map['logo_path'],
      isDefault: map['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'corporate_name': corporateName,
      'cnpj': cnpj,
      'cep': cep,
      'street': street,
      'number': number,
      'complement': complement,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'phone': phone,
      'email': email,
      'logo_path': logoPath,
      'is_default': isDefault,
    };
  }

  Company copyWith({
    int? id,
    String? name,
    String? corporateName,
    String? cnpj,
    String? cep,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
    String? phone,
    String? email,
    String? logoPath,
    bool? isDefault,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      corporateName: corporateName ?? this.corporateName,
      cnpj: cnpj ?? this.cnpj,
      cep: cep ?? this.cep,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoPath: logoPath ?? this.logoPath,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}