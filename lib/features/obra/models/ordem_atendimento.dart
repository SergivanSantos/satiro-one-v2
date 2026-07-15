class OrdemAtendimento {
  final String id;
  final String ordemServicoId;
  final String? servicoId;
  final int? tecnicoId;
  final DateTime? dataCheckin;
  final DateTime? dataCheckout;
  final String status;
  final String? solucao;
  final String? pendencias;
  final String? observacoes;
  final List<String> fotos;

  OrdemAtendimento({
    required this.id,
    required this.ordemServicoId,
    this.servicoId,
    this.tecnicoId,
    this.dataCheckin,
    this.dataCheckout,
    this.status = 'pendente',
    this.solucao,
    this.pendencias,
    this.observacoes,
    this.fotos = const [],
  });

  factory OrdemAtendimento.fromMap(Map<String, dynamic> map) {
    return OrdemAtendimento(
      id: map['id'] ?? '',
      ordemServicoId: map['ordem_servico_id'] ?? '',
      servicoId: map['servico_id'],
      tecnicoId: map['tecnico_id'],
      dataCheckin: map['data_checkin'] != null ? DateTime.parse(map['data_checkin']) : null,
      dataCheckout: map['data_checkout'] != null ? DateTime.parse(map['data_checkout']) : null,
      status: map['status'] ?? 'pendente',
      solucao: map['solucao'],
      pendencias: map['pendencias'],
      observacoes: map['observacoes'],
      fotos: List<String>.from(map['fotos'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ordem_servico_id': ordemServicoId,
      'servico_id': servicoId,
      'tecnico_id': tecnicoId,
      'data_checkin': dataCheckin?.toIso8601String(),
      'data_checkout': dataCheckout?.toIso8601String(),
      'status': status,
      'solucao': solucao,
      'pendencias': pendencias,
      'observacoes': observacoes,
      'fotos': fotos,
    };
  }
}