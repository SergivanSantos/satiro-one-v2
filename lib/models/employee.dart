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
  final String? cargo;
  final String? role;
  final String? branchId;
  final List<String>? allowedBranchIds;
  final bool isActive;
  final String? photoPath;
  final DateTime? hireDate;
  final double? commissionRate;

  // ==================== CAMPOS DE CARGA HORÁRIA ====================
  final double dailyWorkHours;           // Carga horária diária (ex: 4.0, 6.0, 8.0, 9.0)
  final List<int>? workDaysOfWeek;       // Dias da semana que trabalha (1=Seg ... 6=Sab)
  final String workScheduleType;         // 'standard_9x8', 'full_time', 'part_time', 'custom'

  final String? statusAfastamento;
  final DateTime? dataInicioAfastamento;
  final DateTime? dataFimAfastamento;
  final DateTime? dataSaida;
  final String? motivoSaida;
  final String? bankName;
  final String? agency;
  final String? account;
  final String? pixKey;
  final String? supabaseUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.cargo,
    this.role = 'tecnico',
    this.branchId,
    this.allowedBranchIds,
    this.isActive = true,
    this.photoPath,
    this.hireDate,
    this.commissionRate,

    // Valores padrão para manter compatibilidade com dados antigos
    this.dailyWorkHours = 8.0,
    this.workDaysOfWeek,
    this.workScheduleType = 'standard_9x8',   // Padrão antigo da empresa

    this.statusAfastamento,
    this.dataInicioAfastamento,
    this.dataFimAfastamento,
    this.dataSaida,
    this.motivoSaida,
    this.bankName,
    this.agency,
    this.account,
    this.pixKey,
    this.supabaseUserId,
    this.createdAt,
    this.updatedAt,
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
      'cargo': cargo,
      'role': role,
      'branch_id': branchId,
      'allowed_branch_ids': allowedBranchIds,
      'is_active': isActive,
      'photo_path': photoPath,
      'hire_date': hireDate?.toIso8601String(),
      'commission_rate': commissionRate,

      // Novos campos
      'daily_work_hours': dailyWorkHours,
      'work_days_of_week': workDaysOfWeek,
      'work_schedule_type': workScheduleType,

      'status_afastamento': statusAfastamento,
      'data_inicio_afastamento': dataInicioAfastamento?.toIso8601String(),
      'data_fim_afastamento': dataFimAfastamento?.toIso8601String(),
      'data_saida': dataSaida?.toIso8601String(),
      'motivo_saida': motivoSaida,
      'bank_name': bankName,
      'agency': agency,
      'account': account,
      'pix_key': pixKey,
      'supabase_user_id': supabaseUserId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int?,
      name: map['name'] ?? 'Sem nome',
      cpf: map['cpf'] as String?,
      rg: map['rg'] as String?,
      birthDate: map['birth_date'] != null ? DateTime.tryParse(map['birth_date']) : null,
      phone: map['phone'] as String?,
      whatsapp: map['whatsapp'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      cargo: map['cargo'] as String?,
      role: map['role'] as String?,
      branchId: map['branch_id'] as String?,
      allowedBranchIds: (map['allowed_branch_ids'] as List<dynamic>?)?.cast<String>(),
      isActive: map['is_active'] as bool? ?? true,
      photoPath: map['photo_path'] as String?,
      hireDate: map['hire_date'] != null ? DateTime.tryParse(map['hire_date']) : null,
      commissionRate: (map['commission_rate'] as num?)?.toDouble(),

      // Novos campos com fallback seguro
      dailyWorkHours: (map['daily_work_hours'] as num?)?.toDouble() ?? 8.0,
      workDaysOfWeek: (map['work_days_of_week'] as List<dynamic>?)?.cast<int>(),
      workScheduleType: map['work_schedule_type'] as String? ?? 'standard_9x8',

      statusAfastamento: map['status_afastamento'] as String?,
      dataInicioAfastamento: map['data_inicio_afastamento'] != null
          ? DateTime.tryParse(map['data_inicio_afastamento']) : null,
      dataFimAfastamento: map['data_fim_afastamento'] != null
          ? DateTime.tryParse(map['data_fim_afastamento']) : null,
      dataSaida: map['data_saida'] != null
          ? DateTime.tryParse(map['data_saida']) : null,
      motivoSaida: map['motivo_saida'] as String?,
      bankName: map['bank_name'] as String?,
      agency: map['agency'] as String?,
      account: map['account'] as String?,
      pixKey: map['pix_key'] as String?,
      supabaseUserId: map['supabase_user_id'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
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
    String? cargo,
    String? role,
    String? branchId,
    List<String>? allowedBranchIds,
    bool? isActive,
    String? photoPath,
    DateTime? hireDate,
    double? commissionRate,
    double? dailyWorkHours,
    List<int>? workDaysOfWeek,
    String? workScheduleType,
    String? statusAfastamento,
    DateTime? dataInicioAfastamento,
    DateTime? dataFimAfastamento,
    DateTime? dataSaida,
    String? motivoSaida,
    String? bankName,
    String? agency,
    String? account,
    String? pixKey,
    String? supabaseUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      cargo: cargo ?? this.cargo,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      allowedBranchIds: allowedBranchIds ?? this.allowedBranchIds,
      isActive: isActive ?? this.isActive,
      photoPath: photoPath ?? this.photoPath,
      hireDate: hireDate ?? this.hireDate,
      commissionRate: commissionRate ?? this.commissionRate,

      dailyWorkHours: dailyWorkHours ?? this.dailyWorkHours,
      workDaysOfWeek: workDaysOfWeek ?? this.workDaysOfWeek,
      workScheduleType: workScheduleType ?? this.workScheduleType,

      statusAfastamento: statusAfastamento ?? this.statusAfastamento,
      dataInicioAfastamento: dataInicioAfastamento ?? this.dataInicioAfastamento,
      dataFimAfastamento: dataFimAfastamento ?? this.dataFimAfastamento,
      dataSaida: dataSaida ?? this.dataSaida,
      motivoSaida: motivoSaida ?? this.motivoSaida,
      bankName: bankName ?? this.bankName,
      agency: agency ?? this.agency,
      account: account ?? this.account,
      pixKey: pixKey ?? this.pixKey,
      supabaseUserId: supabaseUserId ?? this.supabaseUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}