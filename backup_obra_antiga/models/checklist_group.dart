// lib/models/checklist_group.dart
import 'checklist_subgroup.dart';

class ChecklistGroup {
  final int id;
  final String title;
  final int orderIndex;
  final List<ChecklistSubgroup> subgroups;

  ChecklistGroup({
    required this.id,
    required this.title,
    required this.orderIndex,
    this.subgroups = const [],
  });

  ChecklistGroup copyWith({
    int? id,
    String? title,
    int? orderIndex,
    List<ChecklistSubgroup>? subgroups,
  }) {
    return ChecklistGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      subgroups: subgroups ?? this.subgroups,
    );
  }

  factory ChecklistGroup.fromJson(Map<String, dynamic> json, List<ChecklistSubgroup> subgroups) {
    return ChecklistGroup(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      orderIndex: json['order_index'] ?? 0,
      subgroups: subgroups,
    );
  }
}