// lib/features/chamado/models/chamado.dart
import 'package:uuid/uuid.dart';

class Chamado {
  final String id;
  final String codigo;
  final String ordemServicoId;
  final String obraId;
  final DateTime dataAgendada;
  final DateTime? dataRealizacao;
  final int? tecnicoId;
  final String status;
  final String? observacoesGerais;
  final DateTime createdAt;

  // Joins
  final String? obraNome;
  final String? clienteNome;
  final String? tecnicoNome;

  final List<String> servicosIds;

  Chamado({
    String? id,
    String? codigo,
    required this.ordemServicoId,
    required this.obraId,
    required this.dataAgendada,
    this.dataRealizacao,
    this.tecnicoId,
    this.status = 'agendado',
    this.observacoesGerais,
    DateTime? createdAt,
    this.obraNome,
    this.clienteNome,
    this.tecnicoNome,
    List<String>? servicosIds,
  })  : id = id ?? const Uuid().v4(),
        codigo = codigo ?? _gerarCodigo(dataAgendada),
        createdAt = createdAt ?? DateTime.now(),
        servicosIds = servicosIds ?? [];

  static String _gerarCodigo(DateTime data) {
    final ano = data.year.toString().substring(2);
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    final sequencia = (DateTime.now().millisecondsSinceEpoch % 999) + 1;
    return "CH$ano$mes$dia-${sequencia.toString().padLeft(3, '0')}";
  }

  factory Chamado.fromMap(Map<String, dynamic> map) {
    return Chamado(
      id: map['id'] ?? '',
      codigo: map['codigo'] ?? '',
      ordemServicoId: map['ordem_servico_id'] ?? '',
      obraId: map['obra_id'] ?? '',
      dataAgendada: DateTime.tryParse(map['data_agendada'] ?? '') ?? DateTime.now(),
      dataRealizacao: map['data_realizacao'] != null
          ? DateTime.tryParse(map['data_realizacao'])
          : null,
      tecnicoId: map['tecnico_id'] is int
          ? map['tecnico_id']
          : int.tryParse(map['tecnico_id']?.toString() ?? ''),
      status: map['status'] ?? 'agendado',
      observacoesGerais: map['observacoes_gerais'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),



      obraNome: map['obra']?['nome'],
      clienteNome: map['obra']?['cliente']?['nome'],
      tecnicoNome: map['tecnico']?['name'],

      servicosIds: List<String>.from(map['servicos_ids'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'ordem_servico_id': ordemServicoId,
      'obra_id': obraId,
      'data_agendada': dataAgendada.toIso8601String().split('T').first,
      'data_realizacao': dataRealizacao?.toIso8601String(),
      'tecnico_id': tecnicoId,
      'status': status,
      'observacoes_gerais': observacoesGerais,
      'created_at': createdAt.toIso8601String(),
      'servicos_ids': servicosIds,
    };
  }


  String get numeroDisplay => codigo.isNotEmpty ? codigo : "CH-${id.substring(0, 8)}";

  // ==================== HELPERS ====================
  int get quantidadeServicos => servicosIds.length;
  bool get temServicos => servicosIds.isNotEmpty;
  bool get isConcluido => status == 'concluido';
  bool get isAgendado => status == 'agendado';
  bool get isEmAndamento => status == 'em_andamento';

  Chamado copyWith({
    String? id,
    String? ordemServicoId,
    String? obraId,
    DateTime? dataAgendada,
    DateTime? dataRealizacao,
    int? tecnicoId,
    String? status,
    String? observacoesGerais,
    DateTime? createdAt,
    String? obraNome,
    String? clienteNome,
    String? tecnicoNome,
    List<String>? servicosIds,
  }) {
    return Chamado(
      id: id ?? this.id,
      ordemServicoId: ordemServicoId ?? this.ordemServicoId,
      obraId: obraId ?? this.obraId,
      dataAgendada: dataAgendada ?? this.dataAgendada,
      dataRealizacao: dataRealizacao ?? this.dataRealizacao,
      tecnicoId: tecnicoId ?? this.tecnicoId,
      status: status ?? this.status,
      observacoesGerais: observacoesGerais ?? this.observacoesGerais,
      createdAt: createdAt ?? this.createdAt,
      obraNome: obraNome ?? this.obraNome,
      clienteNome: clienteNome ?? this.clienteNome,
      tecnicoNome: tecnicoNome ?? this.tecnicoNome,
      servicosIds: servicosIds ?? this.servicosIds,
    );
  }
}