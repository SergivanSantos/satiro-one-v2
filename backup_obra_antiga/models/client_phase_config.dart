// lib/models/client_phase_config.dart

class ClientPhaseConfig {
  final int? id;                      // ← Alterado para nullable
  final String phaseName;
  final int phaseOrder;
  final String color;
  final bool requiresChecklist;
  final bool isActive;
  final int? checklistId;

  ClientPhaseConfig({
    this.id,                          // ← Removido 'required'
    required this.phaseName,
    required this.phaseOrder,
    this.color = '#2196F3',
    this.requiresChecklist = false,
    this.isActive = true,
    this.checklistId,
  });

  factory ClientPhaseConfig.fromJson(Map<String, dynamic> json) {
    return ClientPhaseConfig(
      id: json['id'] as int?,
      phaseName: json['phase_name'] as String,
      phaseOrder: json['phase_order'] as int,
      color: json['color'] as String? ?? '#2196F3',
      requiresChecklist: json['requires_checklist'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      checklistId: json['checklist_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phase_name': phaseName,
      'phase_order': phaseOrder,
      'color': color,
      'requires_checklist': requiresChecklist,
      'is_active': isActive,
      'checklist_id': checklistId,
    };
  }

  ClientPhaseConfig copyWith({
    int? id,
    String? phaseName,
    int? phaseOrder,
    String? color,
    bool? requiresChecklist,
    bool? isActive,
    int? checklistId,
  }) {
    return ClientPhaseConfig(
      id: id ?? this.id,
      phaseName: phaseName ?? this.phaseName,
      phaseOrder: phaseOrder ?? this.phaseOrder,
      color: color ?? this.color,
      requiresChecklist: requiresChecklist ?? this.requiresChecklist,
      isActive: isActive ?? this.isActive,
      checklistId: checklistId ?? this.checklistId,
    );
  }

  @override
  String toString() {
    return 'ClientPhaseConfig(id: $id, name: $phaseName, checklistId: $checklistId)';
  }
}