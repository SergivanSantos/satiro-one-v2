// models/environment.dart
class Environment {
  final int? id;
  final String name;
  final int? clientId;
  final bool isGlobal;

  Environment({
    this.id,
    required this.name,
    this.clientId,
    this.isGlobal = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientId': clientId,
      'isGlobal': isGlobal ? 1 : 0,
    };
  }

  factory Environment.fromMap(Map<String, dynamic> map) {
    return Environment(
      id: map['id'] as int?,
      name: map['name'] as String,
      clientId: map['clientId'] as int?,
      isGlobal: (map['isGlobal'] as int? ?? 0) == 1,
    );
  }

  Environment copyWith({
    int? id,
    String? name,
    int? clientId,
    bool? isGlobal,
  }) {
    return Environment(
      id: id ?? this.id,
      name: name ?? this.name,
      clientId: clientId ?? this.clientId,
      isGlobal: isGlobal ?? this.isGlobal,
    );
  }
}