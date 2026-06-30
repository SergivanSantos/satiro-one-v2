// lib/features/obra/models/obra.dart
class Obra {
  final String id;
  final String companyId;
  final String clientId;
  final String name;
  final String? address;
  final String status;
  final DateTime? dataInicio;
  final DateTime? dataPrevistaFim;
  final DateTime? dataRealFim;
  final double valorOrcado;
  final double valorExecutado;
  final String? observacoes;

  // Campos calculados (vamos popular depois)
  double percentualGeral = 0.0;

  Obra({
    required this.id,
    required this.companyId,
    required this.clientId,
    required this.name,
    this.address,
    this.status = 'em_andamento',
    this.dataInicio,
    this.dataPrevistaFim,
    this.dataRealFim,
    this.valorOrcado = 0.0,
    this.valorExecutado = 0.0,
    this.observacoes,
    this.percentualGeral = 0.0,
  });

  factory Obra.fromMap(Map<String, dynamic> map) {
    return Obra(
      id: map['id'],
      companyId: map['company_id'],
      clientId: map['client_id'],
      name: map['name'],
      address: map['address'],
      status: map['status'] ?? 'em_andamento',
      dataInicio: map['data_inicio'] != null ? DateTime.parse(map['data_inicio']) : null,
      dataPrevistaFim: map['data_prevista_fim'] != null ? DateTime.parse(map['data_prevista_fim']) : null,
      dataRealFim: map['data_real_fim'] != null ? DateTime.parse(map['data_real_fim']) : null,
      valorOrcado: (map['valor_orcado'] ?? 0.0).toDouble(),
      valorExecutado: (map['valor_executado'] ?? 0.0).toDouble(),
      observacoes: map['observacoes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'company_id': companyId,
      'client_id': clientId,
      'name': name,
      'address': address,
      'status': status,
      'data_inicio': dataInicio?.toIso8601String(),
      'data_prevista_fim': dataPrevistaFim?.toIso8601String(),
      'data_real_fim': dataRealFim?.toIso8601String(),
      'valor_orcado': valorOrcado,
      'valor_executado': valorExecutado,
      'observacoes': observacoes,
    };
  }
}