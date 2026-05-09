// lib/models/checklist_execution_item.dart
class ChecklistExecutionItem {
  final int id;
  final int executionId;
  final int itemId;
  final String status;        // 'sim', 'nao', 'na', 'pendente'
  final String? observation;
  final String? photoPath;

  ChecklistExecutionItem({
    required this.id,
    required this.executionId,
    required this.itemId,
    required this.status,
    this.observation,
    this.photoPath,
  });

  factory ChecklistExecutionItem.fromJson(Map<String, dynamic> json) {
    return ChecklistExecutionItem(
      id: json['id'],
      executionId: json['execution_id'],
      itemId: json['item_id'],
      status: json['status'] ?? 'pendente',
      observation: json['observation'],
      photoPath: json['photo_path'],
    );
  }
}