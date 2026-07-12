// lib/features/material/models/obra_material.dart
class ObraMaterial {
  final String id;
  final String obraId;
  final String materialId;
  final String materialNome;
  final String unidade;
  final double quantidade;
  final String status;
  final String? faseId;
  final String? fotoUrl;
  final DateTime? dataEntrega;

  ObraMaterial({
    required this.id,
    required this.obraId,
    required this.materialId,
    required this.materialNome,
    required this.unidade,
    required this.quantidade,
    required this.status,
    this.faseId,
    this.fotoUrl,
    this.dataEntrega,
  });

  factory ObraMaterial.fromMap(Map<String, dynamic> map) {
    return ObraMaterial(
      id: map['id'] ?? '',
      obraId: map['obra_id'] ?? '',
      materialId: map['material_id'] ?? '',
      materialNome: map['material']?['nome'] ?? map['material_nome'] ?? '',
      unidade: map['material']?['unidade'] ?? map['unidade'] ?? 'un',
      quantidade: (map['quantidade'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'a_comprar',
      faseId: map['fase_id'],
      fotoUrl: map['foto_url'],
      dataEntrega: map['data_entrega'] != null ? DateTime.parse(map['data_entrega']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'obra_id': obraId,
      'material_id': materialId,
      'quantidade': quantidade,
      'status': status,
      'fase_id': faseId,
      'foto_url': fotoUrl,
      'data_entrega': dataEntrega?.toIso8601String(),
      // 'observacao' removido
    };
  }
}