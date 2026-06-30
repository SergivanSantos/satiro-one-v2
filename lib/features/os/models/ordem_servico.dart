// lib/features/os/models/ordem_servico.dart
class OrdemServico {
  final String id;
  final String obraId;
  final String? faseId;
  final String clienteId;
  final DateTime data;
  final String status;
  final String? tecnicoId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? observacoesGerais;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Campos computados (para facilitar exibição nas telas)
  String? obraNome;
  String? faseNome;
  String? tecnicoNome;
  String? clienteNome;

  OrdemServico({
    required this.id,
    required this.obraId,
    this.faseId,
    required this.clienteId,
    required this.data,
    this.status = 'pendente',
    this.tecnicoId,
    this.checkIn,
    this.checkOut,
    this.observacoesGerais,
    required this.createdAt,
    this.updatedAt,
    this.obraNome,
    this.faseNome,
    this.tecnicoNome,
    this.clienteNome,
  });

  factory OrdemServico.fromMap(Map<String, dynamic> map) {
    return OrdemServico(
      id: map['id'],
      obraId: map['obra_id'],
      faseId: map['fase_id'],
      clienteId: map['cliente_id'],
      data: DateTime.parse(map['data']),
      status: map['status'] ?? 'pendente',
      tecnicoId: map['tecnico_id'],
      checkIn: map['check_in'] != null ? DateTime.parse(map['check_in']) : null,
      checkOut: map['check_out'] != null ? DateTime.parse(map['check_out']) : null,
      observacoesGerais: map['observacoes_gerais'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'obra_id': obraId,
      'fase_id': faseId,
      'cliente_id': clienteId,
      'data': data.toIso8601String().split('T')[0], // apenas data
      'status': status,
      'tecnico_id': tecnicoId,
      'check_in': checkIn?.toIso8601String(),
      'check_out': checkOut?.toIso8601String(),
      'observacoes_gerais': observacoesGerais,
    };
  }

  // Métodos auxiliares para exibição
  String get statusFormatado {
    switch (status.toLowerCase()) {
      case 'concluida':
        return 'Concluída';
      case 'em_andamento':
        return 'Em Andamento';
      case 'cancelada':
        return 'Cancelada';
      default:
        return 'Pendente';
    }
  }

  bool get isConcluida => status.toLowerCase() == 'concluida';
  bool get isEmAndamento => status.toLowerCase() == 'em_andamento';
}