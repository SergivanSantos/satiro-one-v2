class Log {
  final int? id;
  final String action;
  final String? description;
  final String timestamp;

  Log({
    this.id,
    required this.action,
    this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'description': description,
      'timestamp': timestamp,
    };
  }

  factory Log.fromMap(Map<String, dynamic> map) {
    return Log(
      id: map['id'] as int?,
      action: map['action'] ?? 'N/A',
      description: map['description'] as String?,
      timestamp: map['timestamp'] ?? '',
    );
  }
}