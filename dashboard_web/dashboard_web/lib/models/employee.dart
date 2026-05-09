// lib/models/employee.dart
class Employee {
  final int? id;
  final String name;
  final String? cpf;
  final String? rg;
  final DateTime? birthDate;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? address;
  final String? role;
  final bool isActive;
  final String? photoPath;
  final DateTime? hireDate;
  final double? commissionRate;
  final DateTime? dataSaida;
  final String? motivoSaida;
  final String? statusAfastamento;
  final DateTime? dataInicioAfastamento;
  final DateTime? dataFimAfastamento;
  final String? bankName;
  final String? agency;
  final String? account;
  final String? pixKey;

  Employee({
    this.id,
    required this.name,
    this.cpf,
    this.rg,
    this.birthDate,
    this.phone,
    this.whatsapp,
    this.email,
    this.address,
    this.role,
    this.isActive = true,
    this.photoPath,
    this.hireDate,
    this.commissionRate,
    this.dataSaida,
    this.motivoSaida,
    this.statusAfastamento,
    this.dataInicioAfastamento,
    this.dataFimAfastamento,
    this.bankName,
    this.agency,
    this.account,
    this.pixKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cpf': cpf,
      'rg': rg,
      'birth_date': birthDate?.toIso8601String(),
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'address': address,
      'role': role,
      'is_active': isActive,
      'photo_path': photoPath,
      'hire_date': hireDate?.toIso8601String(),
      'commission_rate': commissionRate,
      'data_saida': dataSaida?.toIso8601String(),
      'motivo_saida': motivoSaida,
      'status_afastamento': statusAfastamento,
      'data_inicio_afastamento': dataInicioAfastamento?.toIso8601String(),
      'data_fim_afastamento': dataFimAfastamento?.toIso8601String(),
      'bank_name': bankName,
      'agency': agency,
      'account': account,
      'pix_key': pixKey,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int?,
      name: map['name'] as String,
      cpf: map['cpf'] as String?,
      rg: map['rg'] as String?,
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date']) : null,
      phone: map['phone'] as String?,
      whatsapp: map['whatsapp'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      role: map['role'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      photoPath: map['photo_path'] as String?,
      hireDate: map['hire_date'] != null ? DateTime.parse(map['hire_date']) : null,
      commissionRate: map['commission_rate'] != null
          ? (map['commission_rate'] is int
          ? (map['commission_rate'] as int).toDouble()
          : map['commission_rate'] as double)
          : null,
      dataSaida: map['data_saida'] != null ? DateTime.parse(map['data_saida']) : null,
      motivoSaida: map['motivo_saida'] as String?,
      statusAfastamento: map['status_afastamento'] as String?,
      dataInicioAfastamento: map['data_inicio_afastamento'] != null ? DateTime.parse(map['data_inicio_afastamento']) : null,
      dataFimAfastamento: map['data_fim_afastamento'] != null ? DateTime.parse(map['data_fim_afastamento']) : null,
      bankName: map['bank_name'] as String?,
      agency: map['agency'] as String?,
      account: map['account'] as String?,
      pixKey: map['pix_key'] as String?,
    );
  }

  Employee copyWith({
    int? id,
    String? name,
    String? cpf,
    String? rg,
    DateTime? birthDate,
    String? phone,
    String? whatsapp,
    String? email,
    String? address,
    String? role,
    bool? isActive,
    String? photoPath,
    DateTime? hireDate,
    double? commissionRate,
    DateTime? dataSaida,
    String? motivoSaida,
    String? statusAfastamento,
    DateTime? dataInicioAfastamento,
    DateTime? dataFimAfastamento,
    String? bankName,
    String? agency,
    String? account,
    String? pixKey,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      cpf: cpf ?? this.cpf,
      rg: rg ?? this.rg,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      address: address ?? this.address,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      photoPath: photoPath ?? this.photoPath,
      hireDate: hireDate ?? this.hireDate,
      commissionRate: commissionRate ?? this.commissionRate,
      dataSaida: dataSaida ?? this.dataSaida,
      motivoSaida: motivoSaida ?? this.motivoSaida,
      statusAfastamento: statusAfastamento ?? this.statusAfastamento,
      dataInicioAfastamento: dataInicioAfastamento ?? this.dataInicioAfastamento,
      dataFimAfastamento: dataFimAfastamento ?? this.dataFimAfastamento,
      bankName: bankName ?? this.bankName,
      agency: agency ?? this.agency,
      account: account ?? this.account,
      pixKey: pixKey ?? this.pixKey,
    );
  }
}