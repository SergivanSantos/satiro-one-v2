// lib/models/travel_request.dart
import 'package:intl/intl.dart';

class TravelRequest {
  final int? id;
  final List<int> employeeIds;        // múltiplos funcionários
  final int clientId;
  final String motivo;
  final String city;
  final String transportType;         // 'carro', 'onibus', 'sem_despesa'
  final int? vehicleId;               // só se for carro
  final DateTime departureDateTime;
  final DateTime returnDateTime;
  final double balsaExpense;
  final double pedagioExpense;
  final double mealDailyRate;         // valor da diária de alimentação
  final int mealDays;                 // dias calculados automaticamente
  final double totalMealValue;
  final double totalAdvance;          // total a adiantar
  final String status;                // 'pendente', 'aprovada', 'rejeitada'
  final int createdBy;
  final int? approvedBy;
  final List<String> attachments;     // urls de comprovantes
  final DateTime createdAt;

  TravelRequest({
    this.id,
    required this.employeeIds,
    required this.clientId,
    required this.motivo,
    required this.city,
    required this.transportType,
    this.vehicleId,
    required this.departureDateTime,
    required this.returnDateTime,
    this.balsaExpense = 0,
    this.pedagioExpense = 0,
    required this.mealDailyRate,
    required this.mealDays,
    required this.totalMealValue,
    required this.totalAdvance,
    this.status = 'pendente',
    required this.createdBy,
    this.approvedBy,
    this.attachments = const [],
    required this.createdAt,
  });

  // Método para calcular dias de alimentação automaticamente
  static int calculateMealDays(DateTime departure, DateTime returnDate) {
    int days = 0;
    DateTime current = departure;

    while (current.isBefore(returnDate) || current.isAtSameMomentAs(returnDate)) {
      // Regra de almoço
      if (current.day != departure.day || departure.hour < 12) {
        days++; // almoço
      }
      // Regra de janta
      if (current.day != returnDate.day || returnDate.hour >= 19) {
        days++; // janta
      }
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  factory TravelRequest.fromMap(Map<String, dynamic> map) {
    return TravelRequest(
      id: map['id'],
      employeeIds: List<int>.from(map['employee_ids'] ?? []),
      clientId: map['client_id'],
      motivo: map['motivo'],
      city: map['city'],
      transportType: map['transport_type'],
      vehicleId: map['vehicle_id'],
      departureDateTime: DateTime.parse(map['departure_datetime']),
      returnDateTime: DateTime.parse(map['return_datetime']),
      balsaExpense: map['balsa_expense']?.toDouble() ?? 0,
      pedagioExpense: map['pedagio_expense']?.toDouble() ?? 0,
      mealDailyRate: map['meal_daily_rate']?.toDouble() ?? 0,
      mealDays: map['meal_days'] ?? 0,
      totalMealValue: map['total_meal_value']?.toDouble() ?? 0,
      totalAdvance: map['total_advance']?.toDouble() ?? 0,
      status: map['status'] ?? 'pendente',
      createdBy: map['created_by'],
      approvedBy: map['approved_by'],
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}