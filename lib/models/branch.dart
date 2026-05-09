class Branch {
  final String id;
  final String name;
  final String? shortName;
  final String city;
  final String state;
  final int? responsibleId; // bigint → int? (correto)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Branch({
    required this.id,
    required this.name,
    this.shortName,
    required this.city,
    required this.state,
    this.responsibleId, // int? é correto
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'] as String,
      name: map['name'] as String,
      shortName: map['short_name'] as String?,
      city: map['city'] as String,
      state: map['state'] as String,
      responsibleId: map['responsible_id'] as int?, // correto (bigint → int?)
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isActive: map['is_active'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'short_name': shortName,
      'city': city,
      'state': state,
      'responsible_id': responsibleId, // int? → null ou número
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  Branch copyWith({
    String? id,
    String? name,
    String? shortName,
    String? city,
    String? state,
    int? responsibleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      city: city ?? this.city,
      state: state ?? this.state,
      responsibleId: responsibleId ?? this.responsibleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}