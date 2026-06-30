class Purchase {
  final int? id;
  final int equipmentId;
  final int? supplierId;
  final int quantity;
  final String purchaseDate;
  final String status;
  final String? observations;

  Purchase({
    this.id,
    required this.equipmentId,
    this.supplierId,
    required this.quantity,
    required this.purchaseDate,
    this.status = 'Pendente',
    this.observations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'supplierId': supplierId,
      'quantity': quantity,
      'purchaseDate': purchaseDate,
      'status': status,
      'observations': observations,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as int?,
      equipmentId: map['equipmentId'] as int,
      supplierId: map['supplierId'] as int?,
      quantity: map['quantity'] as int,
      purchaseDate: map['purchaseDate'] as String,
      status: map['status'] as String? ?? 'Pendente',
      observations: map['observations'] as String?,
    );
  }
}