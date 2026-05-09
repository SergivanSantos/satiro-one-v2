// lib/models/supplier.dart
class Supplier {
  final int? id;
  final String name;
  final String cnpj;           // Apenas números
  final String cep;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String phone;
  final String email;

  Supplier({
    this.id,
    required this.name,
    required this.cnpj,
    this.cep = '',
    this.street = '',
    this.number = '',
    this.complement,
    this.neighborhood = '',
    this.city = '',
    this.state = '',
    this.phone = '',
    this.email = '',
  });

  Supplier copyWith({
    int? id,
    String? name,
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
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
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
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      cnpj: map['cnpj'] as String? ?? '',
      cep: map['cep'] as String? ?? '',
      street: map['street'] as String? ?? '',
      number: map['number'] as String? ?? '',
      complement: map['complement'] as String?,
      neighborhood: map['neighborhood'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }
}