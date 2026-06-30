// lib/models/checklist_item.dart
class ChecklistItem {
  final int id;
  final String title;
  final String? description;
  final String type;
  final bool isRequired;
  final List<String>? options;
  final int orderIndex;

  ChecklistItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.isRequired,
    this.options,
    this.orderIndex = 0,
  });

  ChecklistItem copyWith({
    int? id,
    String? title,
    String? description,
    String? type,
    bool? isRequired,
    List<String>? options,
    int? orderIndex,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      options: options ?? this.options,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'sn',
      isRequired: json['is_required'] ?? true,
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      orderIndex: json['order_index'] ?? 0,
    );
  }
}