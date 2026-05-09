class Employee {
  final int? id;
  final String name;
  final String role;

  Employee({
    this.id,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int?,
      name: map['name'] as String,
      role: map['role'] as String,
    );
  }
}