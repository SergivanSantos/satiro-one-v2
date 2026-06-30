class City {
  final int? id;
  final String name;
  final String state;

  City({
    this.id,
    required this.name,
    required this.state,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'state': state,
    };
  }

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'] as int?,
      name: map['name'] as String,
      state: map['state'] as String,
    );
  }
}