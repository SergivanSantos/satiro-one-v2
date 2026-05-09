class TimeEntry {
  final String id;
  final String employeeId;
  final String branchId;
  final String entryType; // 'entrada', 'saida_almoco', 'retorno_almoco', 'saida'
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String createdBy;
  final String? editedBy;
  final String? editReason;

  TimeEntry({
    required this.id,
    required this.employeeId,
    required this.branchId,
    required this.entryType,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.createdBy,
    this.editedBy,
    this.editReason,
  });

  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map['id'],
      employeeId: map['employee_id'],
      branchId: map['branch_id'],
      entryType: map['entry_type'],
      timestamp: DateTime.parse(map['timestamp']),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      accuracy: map['accuracy']?.toDouble(),
      createdBy: map['created_by'],
      editedBy: map['edited_by'],
      editReason: map['edit_reason'],
    );
  }
}