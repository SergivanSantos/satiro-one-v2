// lib/features/obra/models/obra_piso.dart
class ObraPiso {
  final String id;
  final String obraId;
  final String nome;
  final int ordem;
  final DateTime? createdAt;

  ObraPiso({
    required this.id,
    required this.obraId,
    required this.nome,
    this.ordem = 0,
    this.createdAt,
  });

  factory ObraPiso.fromMap(Map<String, dynamic> map) {
    return ObraPiso(
      id: map['id'] ?? '',
      obraId: map['obra_id'] ?? '',
      nome: map['nome'] ?? '',
      ordem: map['ordem'] ?? 0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'obra_id': obraId,
      'nome': nome,
      'ordem': ordem,
    };
  }
}