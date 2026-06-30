// lib/features/os/models/ordem_servico_item.dart
class OrdemServicoItem {
  final String id;
  final String ordemServicoId;
  final String obraServicoId;
  final String status;
  final String? observacoesTecnico;
  final List<String> fotos;
  final String? assinaturaUrl;

  OrdemServicoItem({
    required this.id,
    required this.ordemServicoId,
    required this.obraServicoId,
    this.status = 'pendente',
    this.observacoesTecnico,
    this.fotos = const [],
    this.assinaturaUrl,
  });

  factory OrdemServicoItem.fromMap(Map<String, dynamic> map) {
    return OrdemServicoItem(
      id: map['id'],
      ordemServicoId: map['ordem_servico_id'],
      obraServicoId: map['obra_servico_id'],
      status: map['status'] ?? 'pendente',
      observacoesTecnico: map['observacoes_tecnico'],
      fotos: List<String>.from(map['fotos'] ?? []),
      assinaturaUrl: map['assinatura_url'],
    );
  }
}