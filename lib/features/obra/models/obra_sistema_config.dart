// lib/features/obra/models/obra_sistema_config.dart
class ObraSistemaConfig {
  final String id;
  final String obraId;
  final String sistemaId;
  final String? ambienteId;
  final Map<String, dynamic>? respostas; // Respostas das perguntas do wizard

  ObraSistemaConfig({
    required this.id,
    required this.obraId,
    required this.sistemaId,
    this.ambienteId,
    this.respostas,
  });

  factory ObraSistemaConfig.fromMap(Map<String, dynamic> map) {
    return ObraSistemaConfig(
      id: map['id'] ?? '',
      obraId: map['obra_id'] ?? '',
      sistemaId: map['sistema_id'] ?? '',
      ambienteId: map['ambiente_id'],
      respostas: map['respostas'] is Map ? map['respostas'] : null,
    );
  }
}