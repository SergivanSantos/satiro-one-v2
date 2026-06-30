// lib/models/checklist_subgroup.dart
import 'checklist_item.dart';

class ChecklistSubgroup {
  final int id;
  final String title;
  final int orderIndex;
  final List<ChecklistItem> items;

  ChecklistSubgroup({
    required this.id,
    required this.title,
    required this.orderIndex,
    this.items = const [],
  });

  ChecklistSubgroup copyWith({
    int? id,
    String? title,
    int? orderIndex,
    List<ChecklistItem>? items,
  }) {
    return ChecklistSubgroup(
      id: id ?? this.id,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      items: items ?? this.items,
    );
  }

  factory ChecklistSubgroup.fromJson(Map<String, dynamic> json, List<ChecklistItem> items) {
    return ChecklistSubgroup(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      orderIndex: json['order_index'] ?? 0,
      items: items,
    );
  }
}