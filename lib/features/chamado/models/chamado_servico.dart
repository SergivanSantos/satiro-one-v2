class ChamadoServico {
  final String id;
  final String chamadoId;
  final String servicoId;
  final String status; // pendente, concluido, pendente_retorno
  final String? solucao;
  final String? pendencias;
  final List<String> fotos;
  final DateTime? dataExecucao;

  ChamadoServico({
    required this.id,
    required this.chamadoId,
    required this.servicoId,
    this.status = 'pendente',
    this.solucao,
    this.pendencias,
    this.fotos = const [],
    this.dataExecucao,
  });

  factory ChamadoServico.fromMap(Map<String, dynamic> map) {
    return ChamadoServico(
      id: map['id'],
      chamadoId: map['chamado_id'],
      servicoId: map['servico_id'],
      status: map['status'] ?? 'pendente',
      solucao: map['solucao'],
      pendencias: map['pendencias'],
      fotos: List<String>.from(map['fotos'] ?? []),
      dataExecucao: map['data_execucao'] != null
          ? DateTime.parse(map['data_execucao'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chamado_id': chamadoId,
      'servico_id': servicoId,
      'status': status,
      'solucao': solucao,
      'pendencias': pendencias,
      'fotos': fotos,
      'data_execucao': dataExecucao?.toIso8601String(),
    };
  }
}