// lib/features/obra/models/obra_bloco.dart
import 'obra_ambiente.dart';
import 'obra_piso.dart';

class ObraBloco {
  final String id;
  final String obraId;
  final String nome;
  final int ordem;

  final List<ObraPiso> pisos = [];
  final List<ObraAmbiente> ambientesDiretos = [];   // ← Importante

  ObraBloco({
    required this.id,
    required this.obraId,
    required this.nome,
    this.ordem = 0,
  });

  factory ObraBloco.fromMap(Map<String, dynamic> map) {
    return ObraBloco(
      id: map['id'] ?? '',
      obraId: map['obra_id'] ?? '',
      nome: map['nome'] ?? '',
      ordem: map['ordem'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'obra_id': obraId,
      'nome': nome,
      'ordem': ordem,
    };
  }
}