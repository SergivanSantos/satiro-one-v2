// lib/features/obra/models/obra_piso.dart
import 'obra_unidade.dart';

class ObraPiso {
  final String id;
  final String blocoId;
  final String nome;
  final int ordem;
  final List<ObraUnidade> unidades = [];   // ← Adicionado

  ObraPiso({
    required this.id,
    required this.blocoId,
    required this.nome,
    this.ordem = 0,
  });

  factory ObraPiso.fromMap(Map<String, dynamic> map) {
    return ObraPiso(
      id: map['id'],
      blocoId: map['bloco_id'],
      nome: map['nome'],
      ordem: map['ordem'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bloco_id': blocoId,
      'nome': nome,
      'ordem': ordem,
    };
  }

}