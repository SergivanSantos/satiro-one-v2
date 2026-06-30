// lib/models/unit.dart
class Unit {
  final int? id;
  final String name;

  Unit({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }
}