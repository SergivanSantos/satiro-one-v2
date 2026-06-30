import 'package:flutter/material.dart';
import '../../servicos/models/servico.dart';

class FluxoItem {
  String id;
  String titulo;
  String tipo; // 'grupo', 'subgrupo', 'pergunta', 'pergunta_quantidade', 'item', 'servico', 'acao'

  // Hierarquia
  List<FluxoItem> filhos = [];

  // Para serviços
  Servico? servicoSelecionado;

  // Campos comuns
  String? descricao;
  bool obrigatorio;

  // Campos específicos
  bool gerarCamposPorQuantidade; // para pergunta_quantidade
  String? textoDescricao;
  String? textoObservacao;
  String? fasePadrao;
  List<String> opcoes; // para perguntas com escolha

  FluxoItem({
    String? id,
    required this.titulo,
    required this.tipo,
    this.servicoSelecionado,
    this.descricao,
    this.obrigatorio = true,
    this.gerarCamposPorQuantidade = false,
    this.textoDescricao,
    this.textoObservacao,
    this.fasePadrao,
    List<FluxoItem>? filhos,
    List<String>? opcoes,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        filhos = filhos ?? [],
        opcoes = opcoes ?? [];

  factory FluxoItem.fromJson(Map<String, dynamic> json) {
    return FluxoItem(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      tipo: json['tipo'] ?? 'grupo',
      descricao: json['descricao'],
      obrigatorio: json['obrigatorio'] ?? true,
      gerarCamposPorQuantidade: json['gerarCamposPorQuantidade'] ?? false,
      textoDescricao: json['textoDescricao'],
      textoObservacao: json['textoObservacao'],
      fasePadrao: json['fasePadrao'],
      opcoes: json['opcoes'] != null ? List<String>.from(json['opcoes']) : [],
      filhos: json['filhos'] != null
          ? (json['filhos'] as List).map((e) => FluxoItem.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'tipo': tipo,
      if (descricao != null) 'descricao': descricao,
      'obrigatorio': obrigatorio,
      if (gerarCamposPorQuantidade) 'gerarCamposPorQuantidade': gerarCamposPorQuantidade,
      if (textoDescricao != null) 'textoDescricao': textoDescricao,
      if (textoObservacao != null) 'textoObservacao': textoObservacao,
      if (fasePadrao != null) 'fasePadrao': fasePadrao,
      if (opcoes.isNotEmpty) 'opcoes': opcoes,
      if (servicoSelecionado != null) ...{
        'servicoId': servicoSelecionado!.id,
        'servicoNome': servicoSelecionado!.nome,
      },
      if (filhos.isNotEmpty) 'filhos': filhos.map((f) => f.toJson()).toList(),
    };
  }

  int get totalAcoesRecursivo {
    if (tipo == 'grupo' || tipo == 'subgrupo') {
      return filhos.fold(0, (sum, item) => sum + item.totalAcoesRecursivo);
    }
    return 1;
  }
}