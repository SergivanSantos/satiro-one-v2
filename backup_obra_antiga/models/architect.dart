// lib/models/architect.dart
class Architect {
  final int? id;
  final String name;
  final String? phone;
  final String? email;

  const Architect({
    this.id,
    required this.name,
    this.phone,
    this.email,
  });

  // Método para Supabase – NÃO envia 'id' no insert
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
    };
  }

  factory Architect.fromJson(Map<String, dynamic> json) {
    return Architect(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Sem nome',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Architect copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
  }) {
    return Architect(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  @override
  String toString() {
    return 'Architect(id: $id, name: $name)';
  }
}