// lib/features/fase/models/obra_fase.dart
import 'fase.dart';

class ObraFase {
  final String id;
  final String obraId;
  final String faseId;
  final int ordem;
  final String status;
  final DateTime? dataInicioPrevista;
  final DateTime? dataFimPrevista;
  final DateTime? dataInicioReal;
  final DateTime? dataFimReal;
  final Fase? fase;

  ObraFase({
    required this.id,
    required this.obraId,
    required this.faseId,
    required this.ordem,
    required this.status,
    this.dataInicioPrevista,
    this.dataFimPrevista,
    this.dataInicioReal,
    this.dataFimReal,
    this.fase,
  });

  factory ObraFase.fromMap(Map<String, dynamic> map) {
    return ObraFase(
      id: map['id'] ?? '',
      obraId: map['obra_id'] ?? '',
      faseId: map['fase_id'] ?? '',
      ordem: map['ordem'] ?? 0,
      status: map['status'] ?? 'pendente',
      dataInicioPrevista: map['data_inicio_prevista'] != null
          ? DateTime.tryParse(map['data_inicio_prevista'].toString())
          : null,
      dataFimPrevista: map['data_fim_prevista'] != null
          ? DateTime.tryParse(map['data_fim_prevista'].toString())
          : null,
      dataInicioReal: map['data_inicio_real'] != null
          ? DateTime.tryParse(map['data_inicio_real'].toString())
          : null,
      dataFimReal: map['data_fim_real'] != null
          ? DateTime.tryParse(map['data_fim_real'].toString())
          : null,
      fase: map['fase'] != null ? Fase.fromMap(map['fase']) : null,
    );
  }
}