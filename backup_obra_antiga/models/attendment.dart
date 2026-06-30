// lib/models/attendment.dart
class Attendment {
  final int? id;
  final int clientId;
  final String type;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime? concludedAt;
  final int? employeeId;
  final int? checklistExecutionId;

  Attendment({
    this.id,
    required this.clientId,
    required this.type,
    this.description,
    required this.status,
    required this.createdAt,
    this.concludedAt,
    this.employeeId,
    this.checklistExecutionId,
  });

  factory Attendment.fromJson(Map<String, dynamic> json) {
    return Attendment(
      id: json['id'],
      clientId: json['client_id'],
      type: json['type'],
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      concludedAt: json['concluded_at'] != null ? DateTime.parse(json['concluded_at']) : null,
      employeeId: json['employee_id'],
      checklistExecutionId: json['checklist_execution_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'type': type,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'concluded_at': concludedAt?.toIso8601String(),
      'employee_id': employeeId,
      'checklist_execution_id': checklistExecutionId,
    };
  }
}