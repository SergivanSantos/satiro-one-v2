class ChamadoItem {
  final String id;
  final String chamadoId;
  final String ambienteId;
  final String servicoNome;
  final int quantidadeSolicitada;
  final String? observacoes;

  ChamadoItem({
    required this.id,
    required this.chamadoId,
    required this.ambienteId,
    required this.servicoNome,
    required this.quantidadeSolicitada,
    this.observacoes,
  });
}