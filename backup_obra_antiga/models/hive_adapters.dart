import 'package:hive/hive.dart';

part 'hive_adapters.g.dart';

@HiveType(typeId: 0)
class HiveClientPendency extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  int clientId;

  @HiveField(2)
  String description;

  @HiveField(3)
  String priority;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String status;

  @HiveField(6)
  DateTime? resolvedAt;

  @HiveField(7)
  String? solution;

  HiveClientPendency({
    this.id,
    required this.clientId,
    required this.description,
    required this.priority,
    required this.createdAt,
    this.status = 'pendente',
    this.resolvedAt,
    this.solution,
  });
}

@HiveType(typeId: 1)
class HivePontoRegistro extends HiveObject {
  @HiveField(0)
  int employeeId;

  @HiveField(1)
  String entryType; // entrada, saida_almoco, retorno_almoco, saida

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  double? latitude;

  @HiveField(4)
  double? longitude;

  HivePontoRegistro({
    required this.employeeId,
    required this.entryType,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });
}