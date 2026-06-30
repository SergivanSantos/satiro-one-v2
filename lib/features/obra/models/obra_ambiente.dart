// lib/features/obra/models/obra_ambiente.dart
class ObraAmbiente {
  final String id;
  final String obraId;
  final String? obraPisoId;     // Referência ao piso (melhor prática)
  final String nome;
  final String? pisoNome;       // Nome do piso como string (como você tem atualmente)
  final int ordem;
  final DateTime? createdAt;

  ObraAmbiente({
    required this.id,
    required this.obraId,
    this.obraPisoId,
    required this.nome,
    this.pisoNome,
    this.ordem = 0,
    this.createdAt,
  });

  factory ObraAmbiente.fromMap(Map<String, dynamic> map) {
    return ObraAmbiente(
      id: map['id'] ?? '',
      obraId: map['obra_id'] ?? '',
      obraPisoId: map['obra_piso_id'],
      nome: map['nome'] ?? '',
      pisoNome: map['piso_nome'],
      ordem: map['ordem'] ?? 0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'obra_id': obraId,
      'obra_piso_id': obraPisoId,
      'nome': nome,
      'piso_nome': pisoNome,
      'ordem': ordem,
    };
  }
}