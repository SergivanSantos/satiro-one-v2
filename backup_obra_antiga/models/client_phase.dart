// lib/models/client_phase.dart
import 'package:intl/intl.dart';

class ClientPhase {
  final int id;
  final int clientId;
  final int phaseConfigId;
  final String phaseName;
  final int phaseOrder;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;           // em_andamento, concluida, atrasada, pendente, cancelada
  final String? notes;
  final DateTime createdAt;

  // Getters
  bool get isCompleted => status == 'concluida';
  bool get isCurrent => status == 'em_andamento';
  bool get isDelayed => status == 'atrasada';
  bool get isPending => status == 'pendente';

  ClientPhase({
    required this.id,
    required this.clientId,
    required this.phaseConfigId,
    required this.phaseName,
    required this.phaseOrder,
    this.startDate,
    this.endDate,
    this.status = 'pendente',
    this.notes,
    required this.createdAt,
  });

  // copyWith corrigido com isCurrent
  ClientPhase copyWith({
    int? id,
    int? clientId,
    int? phaseConfigId,
    String? phaseName,
    int? phaseOrder,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? notes,
    DateTime? createdAt,
    bool? isCurrent,        // ← Adicionado
  }) {
    return ClientPhase(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      phaseConfigId: phaseConfigId ?? this.phaseConfigId,
      phaseName: phaseName ?? this.phaseName,
      phaseOrder: phaseOrder ?? this.phaseOrder,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ClientPhase.fromJson(Map<String, dynamic> json) {
    return ClientPhase(
      id: json['id'] as int,
      clientId: json['client_id'] as int,
      phaseConfigId: json['phase_config_id'] as int,
      phaseName: json['phase_name'] as String? ?? 'Fase Desconhecida',
      phaseOrder: json['phase_order'] as int,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'] as String) : null,
      status: json['status'] as String? ?? 'pendente',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}