import 'obra_bloco.dart';

class ObraDraft {
  String? id;
  String nome;
  List<ObraBloco> blocos = [];

  ObraDraft({this.id, required this.nome});

  // Converte o rascunho para salvar no banco depois
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      // Outros campos da obra...
    };
  }
}