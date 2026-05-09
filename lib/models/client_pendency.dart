// lib/models/client_pendency.dart
class ClientPendency {
  final int? id;
  final int clientId;
  final String description;
  final String priority; // baixa, media, alta, urgente
  final String status;   // pendente, resolvida
  final DateTime createdAt;
  final int? createdBy;
  final DateTime? resolvedAt;
  final int? resolvedBy;
  final DateTime updatedAt;
  final int? checklistExecutionId; // ← adicionado para integração com checklist


  ClientPendency({
    this.id,
    required this.clientId,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.createdBy,
    this.resolvedAt,
    this.resolvedBy,
    required this.updatedAt,
    this.checklistExecutionId,

  });

  factory ClientPendency.fromJson(Map<String, dynamic> json) {
    return ClientPendency(
      id: json['id'] as int?,
      clientId: json['client_id'] as int,
      description: json['description'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'] as int?,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      resolvedBy: json['resolved_by'] as int?,
      updatedAt: DateTime.parse(json['updated_at']),
      checklistExecutionId: json['checklist_execution_id'] as int?,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'description': description,
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'updated_at': updatedAt.toIso8601String(),
      'checklist_execution_id': checklistExecutionId,
      };
  }
}