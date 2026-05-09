// lib/models/checklist.dart
import 'checklist_group.dart';

class Checklist {
  final int id;
  final String name;
  final List<ChecklistGroup> groups;

  Checklist({
    required this.id,
    required this.name,
    this.groups = const [],
  });

  factory Checklist.fromJson(Map<String, dynamic> json, List<ChecklistGroup> groups) {
    return Checklist(
      id: json['id'],
      name: json['name'],
      groups: groups,
    );
  }
}