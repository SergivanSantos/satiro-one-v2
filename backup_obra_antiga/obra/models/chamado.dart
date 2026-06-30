class Chamado {
  final String id;
  final String obraId;
  final String tecnicoId;
  final String titulo;
  final String descricao;
  final String status; // pendente, em_andamento, concluido, cancelado
  final DateTime dataCriacao;
  final DateTime? dataAgendada;
  final DateTime? dataConclusao;

  Chamado({
    required this.id,
    required this.obraId,
    required this.tecnicoId,
    required this.titulo,
    required this.descricao,
    this.status = 'pendente',
    required this.dataCriacao,
    this.dataAgendada,
    this.dataConclusao,
  });
}