import 'dart:convert';
import 'package:flutter/cupertino.dart';

import 'fluxo_item.dart';

class SistemaConfig {
  final String id;
  final String nome;
  final String descricao;
  final bool ativo;
  final int ordem;

  // Configuração completa do fluxo (árvore hierárquica)
  final List<FluxoItem> fluxo;

  SistemaConfig({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.ativo,
    required this.ordem,
    List<FluxoItem>? fluxo,
  }) : fluxo = fluxo ?? [];

  factory SistemaConfig.fromMap(Map<String, dynamic> map) {
    List<FluxoItem> fluxoList = [];

    try {
      final rawConfig = map['configuracao_json'];

      if (rawConfig != null) {
        final config = rawConfig is String
            ? json.decode(rawConfig)
            : rawConfig;

        final fluxoJson = config['fluxo'] as List<dynamic>? ?? [];

        fluxoList = fluxoJson
            .map((item) => FluxoItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e, stack) {
      debugPrint("❌ Erro ao carregar fluxo do sistema ${map['nome']}: $e");
      debugPrint(stack.toString());
    }

    return SistemaConfig(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      ativo: map['ativo'] ?? true,
      ordem: map['ordem'] ?? 0,
      fluxo: fluxoList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'ordem': ordem,
      'configuracao_json': {
        'fluxo': fluxo.map((item) => item.toJson()).toList(),
      },
    };
  }

  // Método útil para debug
  int get totalAcoes => fluxo.fold(0, (sum, item) => sum + item.totalAcoesRecursivo);
}