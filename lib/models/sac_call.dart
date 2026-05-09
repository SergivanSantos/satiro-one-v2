// lib/models/sac_call.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SacCall {
  final int? id;
  final int clientId;
  final String? clientName;           // join opcional (clients.name)
  final String? obra;                 // join opcional (clients.obra)
  final DateTime openedAt;
  final String? openedBy;             // UUID de auth.users
  final String? callerName;
  final String? title;
  final String description;
  final String priority;              // 'baixa', 'media', 'alta', 'urgente'
  final String status;                // 'aberto', 'alocado', 'em_andamento', 'concluido', 'cancelado'
  final DateTime? plannedDate;
  final String? plannedTime;
  final int? assignedEmployeeId;
  final String? assignedEmployeeName; // join opcional (employees.name)
  final String? solutionDescription;
  final DateTime? solutionAt;
  final List<String>? photos;         // jsonb array de caminhos ou URLs
  final String? pendingReason;        // motivo quando pendente
  final String? beforePhotoUrl;       // URL pública da foto antes
  final String? afterPhotoUrl;        // URL pública da foto depois
  final DateTime createdAt;
  final DateTime updatedAt;

  SacCall({
    this.id,
    required this.clientId,
    this.clientName,
    this.obra,
    required this.openedAt,
    this.openedBy,
    this.callerName,
    this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.plannedDate,
    this.plannedTime,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.solutionDescription,
    this.solutionAt,
    this.photos,
    this.pendingReason,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SacCall.fromJson(Map<String, dynamic> json) {
    return SacCall(
      id: json['id'],
      clientId: json['client_id'],
      clientName: json['clients']?['name'],
      obra: json['clients']?['obra'],
      openedAt: DateTime.parse(json['opened_at']),
      openedBy: json['opened_by'],
      callerName: json['caller_name'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'] ?? 'media',
      status: json['status'] ?? 'aberto',
      plannedDate: json['planned_date'] != null ? DateTime.parse(json['planned_date']) : null,
      plannedTime: json['planned_time'],
      assignedEmployeeId: json['assigned_employee_id'],
      assignedEmployeeName: json['employees']?['name'],
      solutionDescription: json['solution_description'],
      solutionAt: json['solution_at'] != null ? DateTime.parse(json['solution_at']) : null,
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      pendingReason: json['pending_reason'],
      beforePhotoUrl: json['before_photo_url'],
      afterPhotoUrl: json['after_photo_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'client_id': clientId,
      'opened_at': openedAt.toIso8601String(),
      'caller_name': callerName,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'planned_date': plannedDate?.toIso8601String().split('T')[0],
      'planned_time': plannedTime,
      'assigned_employee_id': assignedEmployeeId,
      'solution_description': solutionDescription,
      'solution_at': solutionAt?.toIso8601String(),
      'photos': photos ?? [],
      'before_photo_url': beforePhotoUrl,
      'after_photo_url': afterPhotoUrl,
      'pending_reason': pendingReason,
    };

    // Em insert novo, não envia campos que não são necessários ou que podem causar erro
    if (!forInsert) {
      // Só inclui em updates quando realmente alterados
      if (openedBy != null) map['opened_by'] = openedBy;
    }

    return map;
  }

  SacCall copyWith({
    int? id,
    int? clientId,
    String? clientName,
    String? obra,
    DateTime? openedAt,
    String? openedBy,
    String? callerName,
    String? title,
    String? description,
    String? priority,
    String? status,
    DateTime? plannedDate,
    String? plannedTime,
    int? assignedEmployeeId,
    String? assignedEmployeeName,
    String? solutionDescription,
    DateTime? solutionAt,
    List<String>? photos,
    String? pendingReason,
    String? beforePhotoUrl,
    String? afterPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SacCall(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      obra: obra ?? this.obra,
      openedAt: openedAt ?? this.openedAt,
      openedBy: openedBy ?? this.openedBy,
      callerName: callerName ?? this.callerName,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      plannedDate: plannedDate ?? this.plannedDate,
      plannedTime: plannedTime ?? this.plannedTime,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      assignedEmployeeName: assignedEmployeeName ?? this.assignedEmployeeName,
      solutionDescription: solutionDescription ?? this.solutionDescription,
      solutionAt: solutionAt ?? this.solutionAt,
      photos: photos ?? this.photos,
      pendingReason: pendingReason ?? this.pendingReason,
      beforePhotoUrl: beforePhotoUrl ?? this.beforePhotoUrl,
      afterPhotoUrl: afterPhotoUrl ?? this.afterPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Métodos úteis para exibição
  String get priorityLabel {
    switch (priority) {
      case 'baixa': return 'Baixa';
      case 'media': return 'Média';
      case 'alta': return 'Alta';
      case 'urgente': return 'Urgente';
      default: return priority;
    }
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'urgente': return Colors.red;
      case 'alta': return Colors.orange;
      case 'media': return Colors.blue;
      case 'baixa': return Colors.green;
      default: return Colors.grey;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'aberto': return 'Aberto';
      case 'alocado': return 'Alocado';
      case 'em_andamento': return 'Em Andamento';
      case 'concluido': return 'Concluído';
      case 'cancelado': return 'Cancelado';
      default: return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'concluido': return Colors.green;
      case 'cancelado': return Colors.grey;
      case 'em_andamento': return Colors.orange;
      case 'alocado': return Colors.blue;
      case 'aberto': return Colors.red;
      default: return Colors.grey;
    }
  }

  String get formattedPlannedDate {
    if (plannedDate == null) return 'Não agendado';
    return DateFormat('dd/MM/yyyy').format(plannedDate!);
  }
}