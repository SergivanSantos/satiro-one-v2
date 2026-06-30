enum TipoAcao {
  servico,           // Serviço do catálogo
  perguntaQuantidade, // Pergunta com quantidade + gera campos
  perguntaTexto,     // Pergunta simples (texto ou sim/não)
  itemEstoque,       // Item a ser levado
  itemCompra,        // Item para comprar
}

class FluxoAcao {
  final String id;
  final TipoAcao tipo;
  final String titulo;

  // Configurações comuns
  String? fasePadrao;
  bool aplicarTodosAmbientes;
  List<String> ambientesEspecificos;

  String? observacoesPadrao;        // Observações que vão para o técnico

  // Para Serviços e Itens
  String? servicoId;
  String? itemEstoqueId;

  // Para Perguntas
  bool exigeQuantidade;
  String? unidade;                  // 'un', 'm²', 'pontos', etc.
  bool gerarCamposPorQuantidade;    // Cria N campos de descrição/obs
  String? textoDescricao;           // Ex: "Nome do ponto de luz"
  String? textoObservacao;

  FluxoAcao({
    String? id,
    required this.tipo,
    required this.titulo,
    this.fasePadrao,
    this.aplicarTodosAmbientes = true,
    List<String>? ambientesEspecificos,
    this.observacoesPadrao,
    this.servicoId,
    this.itemEstoqueId,
    this.exigeQuantidade = false,
    this.unidade,
    this.gerarCamposPorQuantidade = false,
    this.textoDescricao,
    this.textoObservacao,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        ambientesEspecificos = ambientesEspecificos ?? [];

  factory FluxoAcao.fromJson(Map<String, dynamic> json) {
    return FluxoAcao(
      id: json['id'],
      tipo: TipoAcao.values.byName(json['tipo'] ?? 'servico'),
      titulo: json['titulo'] ?? '',
      fasePadrao: json['fasePadrao'],
      aplicarTodosAmbientes: json['aplicarTodosAmbientes'] ?? true,
      ambientesEspecificos: List<String>.from(json['ambientesEspecificos'] ?? []),
      observacoesPadrao: json['observacoesPadrao'],
      servicoId: json['servicoId'],
      itemEstoqueId: json['itemEstoqueId'],
      exigeQuantidade: json['exigeQuantidade'] ?? false,
      unidade: json['unidade'],
      gerarCamposPorQuantidade: json['gerarCamposPorQuantidade'] ?? false,
      textoDescricao: json['textoDescricao'],
      textoObservacao: json['textoObservacao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo.name,
      'titulo': titulo,
      'fasePadrao': fasePadrao,
      'aplicarTodosAmbientes': aplicarTodosAmbientes,
      'ambientesEspecificos': ambientesEspecificos,
      'observacoesPadrao': observacoesPadrao,
      'servicoId': servicoId,
      'itemEstoqueId': itemEstoqueId,
      'exigeQuantidade': exigeQuantidade,
      'unidade': unidade,
      'gerarCamposPorQuantidade': gerarCamposPorQuantidade,
      'textoDescricao': textoDescricao,
      'textoObservacao': textoObservacao,
    };
  }
}