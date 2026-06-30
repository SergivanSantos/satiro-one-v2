// lib/models/reservation.dart
class Reservation {
  final int? id;
  final int equipmentId;
  final int clientId;
  final int quantity;
  final String reservationDate;
  final String status;
  final String? observations;
  final int? environmentId;

  Reservation({
    this.id,
    required this.equipmentId,
    required this.clientId,
    required this.quantity,
    String? reservationDate,
    String? status,
    this.observations,
    this.environmentId,
  })  : reservationDate = reservationDate ?? DateTime.now().toIso8601String(),
        status = status ?? 'Pendente';

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] as int?,
      equipmentId: map['equipmentId'] as int,
      clientId: map['clientId'] as int,
      quantity: map['quantity'] as int,
      reservationDate: map['reservationDate'] as String,
      status: map['status'] as String? ?? 'Pendente',
      observations: map['observations'] as String?,
      environmentId: map['environmentId'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'clientId': clientId,
      'quantity': quantity,
      'reservationDate': reservationDate,
      'status': status,
      'observations': observations,
      'environmentId': environmentId,
    };
  }

  Reservation copyWith({
    int? id,
    int? equipmentId,
    int? clientId,
    int? quantity,
    String? reservationDate,
    String? status,
    String? observations,
    int? environmentId,
  }) {
    return Reservation(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      clientId: clientId ?? this.clientId,
      quantity: quantity ?? this.quantity,
      reservationDate: reservationDate ?? this.reservationDate,
      status: status ?? this.status,
      observations: observations ?? this.observations,
      environmentId: environmentId ?? this.environmentId,
    );
  }
}