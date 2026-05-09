class Brand {
  final int? id;
  final String name;

  Brand({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Brand.fromMap(Map<String, dynamic> map) {
    return Brand(
      id: map['id'],
      name: map['name'] ?? 'Desconhecido',
    );
  }
}