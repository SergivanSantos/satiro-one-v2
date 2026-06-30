// lib/features/rh/models/employee.dart
class Employee {
  final int? id;
  final String name;
  final String? cpf;
  final String? rg;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? cargo;
  final String role;                    // ← Essencial para controle de acesso
  final bool isActive;
  final String? photoPath;
  final String? supabaseUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Employee({
    this.id,
    required this.name,
    this.cpf,
    this.rg,
    this.phone,
    this.whatsapp,
    this.email,
    this.cargo,
    this.role = 'tecnico',
    this.isActive = true,
    this.photoPath,
    this.supabaseUserId,
    this.createdAt,
    this.updatedAt,
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int?,
      name: map['name'] ?? 'Sem nome',
      cpf: map['cpf'] as String?,
      rg: map['rg'] as String?,
      phone: map['phone'] as String?,
      whatsapp: map['whatsapp'] as String?,
      email: map['email'] as String?,
      cargo: map['cargo'] as String?,
      role: map['role'] as String? ?? 'tecnico',
      isActive: map['is_active'] as bool? ?? true,
      photoPath: map['photo_path'] as String?,
      supabaseUserId: map['supabase_user_id'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cpf': cpf,
      'rg': rg,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'cargo': cargo,
      'role': role,
      'is_active': isActive,
      'photo_path': photoPath,
      'supabase_user_id': supabaseUserId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Employee copyWith({
    int? id,
    String? name,
    String? cpf,
    String? rg,
    String? phone,
    String? whatsapp,
    String? email,
    String? cargo,
    String? role,
    bool? isActive,
    String? photoPath,
    String? supabaseUserId,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      cpf: cpf ?? this.cpf,
      rg: rg ?? this.rg,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      cargo: cargo ?? this.cargo,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      photoPath: photoPath ?? this.photoPath,
      supabaseUserId: supabaseUserId ?? this.supabaseUserId,
    );
  }

  bool get isAdmin => role.toLowerCase().contains('admin');
  bool get isGerente => role.toLowerCase().contains('gerente');
  bool get isRh => role.toLowerCase().contains('rh');
  bool get isTecnico => role.toLowerCase() == 'tecnico';
}