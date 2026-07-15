// lib/features/obra/models/ordem_servico.dart
import 'package:uuid/uuid.dart';

class OrdemServico {
  final String id;
  final String obraId;
  final String faseId;
  final String titulo;
  final String? descricao;
  final DateTime? dataInicioPrevista;
  final DateTime? dataFimPrevista;
  final String status;

  final List<String> responsaveisIds;   // Sempre String (UUID)
  final List<String> servicosIds;

  // Campos calculados / vindos de join
  final String? obraNome;
  final String? faseNome;

  final DateTime createdAt;

  OrdemServico({
    String? id,
    required this.obraId,
    required this.faseId,
    required this.titulo,
    this.descricao,
    this.dataInicioPrevista,
    this.dataFimPrevista,
    this.status = 'pendente',
    this.responsaveisIds = const [],
    this.servicosIds = const [],
    this.obraNome,
    this.faseNome,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory OrdemServico.fromMap(Map<String, dynamic> map) {
    return OrdemServico(
      id: map['id']?.toString() ?? '',
      obraId: map['obra_id']?.toString() ?? '',
      faseId: map['fase_id']?.toString() ?? '',
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'],
      dataInicioPrevista: map['data_inicio_prevista'] != null
          ? DateTime.parse(map['data_inicio_prevista'])
          : null,
      dataFimPrevista: map['data_fim_prevista'] != null
          ? DateTime.parse(map['data_fim_prevista'])
          : null,
      status: map['status'] ?? 'pendente',

      // Garantia de String
      responsaveisIds: List<String>.from(
        (map['responsaveis_ids'] ?? []).map((e) => e.toString()),
      ),
      servicosIds: List<String>.from(
        (map['servicos_ids'] ?? []).map((e) => e.toString()),
      ),

      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),

      // Joins
      obraNome: map['obra']?['nome'] ?? map['obra_nome'],
      faseNome: map['fase']?['nome'] ?? map['fase_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'obra_id': obraId,
      'fase_id': faseId,
      'titulo': titulo,
      'descricao': descricao,
      'data_inicio_prevista': dataInicioPrevista?.toIso8601String(),
      'data_fim_prevista': dataFimPrevista?.toIso8601String(),
      'status': status,
      'responsaveis_ids': responsaveisIds.isNotEmpty ? responsaveisIds : null,
      'servicos_ids': servicosIds.isNotEmpty ? servicosIds : null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helpers
  bool get isPendente => status == 'pendente';
  bool get isEmAndamento => status == 'em_andamento';
  bool get isConcluida => status == 'concluida';
  bool get isCancelada => status == 'cancelada';

  String get statusDisplay {
    switch (status) {
      case 'pendente': return 'Pendente';
      case 'em_andamento': return 'Em Andamento';
      case 'concluida': return 'Concluída';
      case 'cancelada': return 'Cancelada';
      default: return status.toUpperCase();
    }
  }
}