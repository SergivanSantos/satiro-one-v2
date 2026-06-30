// lib/features/obra/models/selecao_config.dart

class SelecaoConfig {
  String titulo;
  List<OpcaoConfig> opcoes;

  SelecaoConfig({
    required this.titulo,
    this.opcoes = const [],
  });

  // ==================== SERIALIZAÇÃO ====================

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'opcoes': opcoes.map((opcao) => opcao.toJson()).toList(),
    };
  }

  factory SelecaoConfig.fromJson(Map<String, dynamic> json) {
    return SelecaoConfig(
      titulo: json['titulo'] ?? 'Sem título',
      opcoes: (json['opcoes'] as List<dynamic>? ?? [])
          .map((item) => OpcaoConfig.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OpcaoConfig {
  String texto;
  List<String> acoes;
  List<SelecaoConfig> subOpcoes;

  OpcaoConfig({
    required this.texto,
    this.acoes = const [],
    this.subOpcoes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'texto': texto,
      'acoes': acoes,
      'sub_opcoes': subOpcoes.map((sub) => sub.toJson()).toList(),
    };
  }

  factory OpcaoConfig.fromJson(Map<String, dynamic> json) {
    return OpcaoConfig(
      texto: json['texto'] ?? 'Nova Opção',
      acoes: List<String>.from(json['acoes'] ?? []),
      subOpcoes: (json['sub_opcoes'] as List<dynamic>? ?? [])
          .map((item) => SelecaoConfig.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}