// lib/models/constructor.dart
class Constructor {
  final int? id;
  final String name;
  final String? phone;
  final String? email;

  const Constructor({
    this.id,
    required this.name,
    this.phone,
    this.email,
  });

  // Método para Supabase – NÃO envia 'id'
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
    };
  }

  factory Constructor.fromJson(Map<String, dynamic> json) {
    return Constructor(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Sem nome',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Constructor copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
  }) {
    return Constructor(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  @override
  String toString() {
    return 'Constructor(id: $id, name: $name)';
  }
}