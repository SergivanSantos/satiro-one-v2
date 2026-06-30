// lib/features/company/models/company.dart
class Company {
  final String id;
  final String name;
  final String? fantasyName;
  final String? cnpj;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final bool isActive;

  Company({
    required this.id,
    required this.name,
    this.fantasyName,
    this.cnpj,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.isActive = true,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'],
      name: map['name'],
      fantasyName: map['fantasy_name'],
      cnpj: map['cnpj'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      logoUrl: map['logo_url'],
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'fantasy_name': fantasyName,
      'cnpj': cnpj,
      'address': address,
      'phone': phone,
      'email': email,
      'logo_url': logoUrl,
      'is_active': isActive,
    };
  }
}