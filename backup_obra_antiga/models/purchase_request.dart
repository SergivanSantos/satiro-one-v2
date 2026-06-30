class PurchaseRequest {
  final int? id;
  final int equipmentId;
  final int? supplierId;
  final int quantity;
  final String requestDate;
  final String status;
  final String? notes;

  PurchaseRequest({
    this.id,
    required this.equipmentId,
    this.supplierId,
    required this.quantity,
    required this.requestDate,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'supplier_id': supplierId,
      'quantity': quantity,
      'request_date': requestDate, // Alterado de 'request_date' para corresponder ao construtor
      'status': status,
      'notes': notes,
    };
  }

  static PurchaseRequest fromMap(Map<String, dynamic> map) {
    return PurchaseRequest(
      id: map['id'],
      equipmentId: map['equipment_id'],
      supplierId: map['supplier_id'],
      quantity: map['quantity'],
      requestDate: map['request_date'], // Alterado para corresponder ao construtor
      status: map['status'],
      notes: map['notes'],
    );
  }
}