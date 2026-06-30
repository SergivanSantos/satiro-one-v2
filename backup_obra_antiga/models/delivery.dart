// lib/models/delivery.dart
class Delivery {
  final int? id;
  final int clientId;
  final String clientName;
  final String clientDocument;     // OBRIGATÓRIO
  final int equipmentId;
  final int quantity;
  final int employeeId;
  final String? employeeName;
  final int companyId;
  final String? companyName;
  final String? observations;
  final DateTime date;

  Delivery({
    this.id,
    required this.clientId,
    required this.clientName,
    required this.clientDocument,
    required this.equipmentId,
    required this.quantity,
    required this.employeeId,
    this.employeeName,
    required this.companyId,
    this.companyName,
    this.observations,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientDocument': clientDocument,
      'equipmentId': equipmentId,
      'quantity': quantity,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'companyId': companyId,
      'companyName': companyName,
      'observations': observations,
      'date': date.toIso8601String(),
    };
  }

  factory Delivery.fromMap(Map<String, dynamic> map) {
    return Delivery(
      id: map['id'] as int?,
      clientId: map['clientId'] as int,
      clientName: map['clientName'] as String,
      clientDocument: map['clientDocument'] as String,
      equipmentId: map['equipmentId'] as int,
      quantity: map['quantity'] as int,
      employeeId: map['employeeId'] as int,
      employeeName: map['employeeName'] as String?,
      companyId: map['companyId'] as int,
      companyName: map['companyName'] as String?,
      observations: map['observations'] as String?,
      date: DateTime.parse(map['date'] as String),
    );
  }
}