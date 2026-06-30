// lib/features/obra/models/obra_unidade.dart
import 'obra_ambiente.dart';

class ObraUnidade {
  final String id;
  final String pisoId;
  final String nome;
  final String? tipo;
  final int ordem;
  final List<ObraAmbiente> ambientes = [];   // ← Novo nível

  ObraUnidade({
    required this.id,
    required this.pisoId,
    required this.nome,
    this.tipo,
    this.ordem = 0,
  });

  factory ObraUnidade.fromMap(Map<String, dynamic> map) {
    return ObraUnidade(
      id: map['id'],
      pisoId: map['piso_id'],
      nome: map['nome'],
      tipo: map['tipo'],
      ordem: map['ordem'] ?? 0,
    );
  }
}