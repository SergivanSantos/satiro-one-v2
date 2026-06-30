// lib/models/checklist_execution.dart
class ChecklistExecution {
  final int? id;
  final int phaseConfigId;
  final int clientId;
  final int? executedById;
  final DateTime executedAt;
  final String status;                    // 'pendente' ou 'concluido'
  final bool isCompleted;
  final String? signaturePath;
  final String? externalLinkToken;
  final String? generalObservation;

  // === NOVOS CAMPOS ===
  final String? responsibleName;          // Responsável na obra
  final String? responsibleContact;       // Contato do responsável

  ChecklistExecution({
    this.id,
    required this.phaseConfigId,
    required this.clientId,
    this.executedById,
    DateTime? executedAt,
    this.status = 'pendente',
    this.isCompleted = false,
    this.signaturePath,
    this.externalLinkToken,
    this.generalObservation,
    this.responsibleName,
    this.responsibleContact,
  }) : executedAt = executedAt ?? DateTime.now();

  factory ChecklistExecution.fromJson(Map<String, dynamic> json) {
    return ChecklistExecution(
      id: json['id'],
      phaseConfigId: json['phase_config_id'],
      clientId: json['client_id'],
      executedById: json['executed_by_id'],
      executedAt: DateTime.tryParse(json['executed_at'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'pendente',
      isCompleted: json['is_completed'] ?? false,
      signaturePath: json['signature_path'],
      externalLinkToken: json['external_link_token'],
      generalObservation: json['general_observation'],
      responsibleName: json['responsible_name'],
      responsibleContact: json['responsible_contact'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase_config_id': phaseConfigId,
      'client_id': clientId,
      'executed_by_id': executedById,
      'executed_at': executedAt.toIso8601String(),
      'status': status,
      'is_completed': isCompleted,
      'signature_path': signaturePath,
      'external_link_token': externalLinkToken,
      'general_observation': generalObservation,
      'responsible_name': responsibleName,
      'responsible_contact': responsibleContact,
    };
  }
}