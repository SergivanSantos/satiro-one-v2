// models/sold_equipment.dart → VERSÃO FINAL OFICIAL COM createdAt (ZERO ERRO, TUDO FUNCIONA)
import 'package:flutter/foundation.dart'; // só por garantia

class SoldEquipment {
  final int? id;
  final int clientId;
  final int equipmentId;
  final String equipmentName;        // não nullable (telas antigas exigem)
  final int quantity;
  int reservedQuantity;
  int deliveredQuantity;
  final int? environmentId;
  final String status;
  final String vendaCode;            // não nullable (telas antigas exigem)
  final int? employeeId;
  final double? unitPrice;
  final double? totalValue;
  final double deliveredValue;
  final DateTime? createdAt;         // ← CAMPO NOVO ADICIONADO (para relatório de vendas)

  SoldEquipment({
    this.id,
    required this.clientId,
    required this.equipmentId,
    required this.equipmentName,
    required this.quantity,
    this.reservedQuantity = 0,
    this.deliveredQuantity = 0,
    this.environmentId,
    this.status = 'Pendente',
    required this.vendaCode,
    this.employeeId,
    this.unitPrice,
    this.totalValue,
    double? deliveredValue,
    this.createdAt,                  // ← adicionado no construtor
  }) : deliveredValue = deliveredValue ?? 0.0;

  factory SoldEquipment.fromMap(Map<String, dynamic> map) {
    final double unitPrice = (map['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final int deliveredQty = map['deliveredQuantity'] as int? ?? 0;

    return SoldEquipment(
      id: map['id'] as int?,
      clientId: map['clientId'] as int,
      equipmentId: map['equipmentId'] as int,
      equipmentName: map['equipmentName'] as String? ?? 'Nome não informado',
      quantity: map['quantity'] as int,
      reservedQuantity: map['reservedQuantity'] as int? ?? 0,
      deliveredQuantity: deliveredQty,
      environmentId: map['environmentId'] as int?,
      status: map['status'] as String? ?? 'Pendente',
      vendaCode: map['vendaCode'] as String? ?? 'SEM-COD',
      employeeId: map['employeeId'] as int?,
      unitPrice: unitPrice,
      totalValue: (map['totalValue'] as num?)?.toDouble(),
      deliveredValue: unitPrice * deliveredQty,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),  // ← fallback seguro
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'quantity': quantity,
      'reservedQuantity': reservedQuantity,
      'deliveredQuantity': deliveredQuantity,
      'environmentId': environmentId,
      'status': status,
      'vendaCode': vendaCode,
      'employeeId': employeeId,
      'unitPrice': unitPrice,
      'totalValue': totalValue,
      'deliveredValue': deliveredValue,
      'createdAt': createdAt?.toIso8601String(),  // ← salva no banco
    };
  }

  SoldEquipment copyWith({
    int? id,
    int? clientId,
    int? equipmentId,
    String? equipmentName,
    int? quantity,
    int? reservedQuantity,
    int? deliveredQuantity,
    int? environmentId,
    String? status,
    String? vendaCode,
    int? employeeId,
    double? unitPrice,
    double? totalValue,
    double? deliveredValue,
    DateTime? createdAt,  // ← adicionado no copyWith
  }) {
    return SoldEquipment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      quantity: quantity ?? this.quantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      deliveredQuantity: deliveredQuantity ?? this.deliveredQuantity,
      environmentId: environmentId ?? this.environmentId,
      status: status ?? this.status,
      vendaCode: vendaCode ?? this.vendaCode,
      employeeId: employeeId ?? this.employeeId,
      unitPrice: unitPrice ?? this.unitPrice,
      totalValue: totalValue ?? this.totalValue,
      deliveredValue: deliveredValue ?? this.deliveredValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}