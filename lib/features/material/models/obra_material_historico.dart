// lib/features/material/models/obra_material_historico.dart

import '../../obra/models/obra_material.dart';

class ObraMaterialHistorico {
  final String id;
  final String obraMaterialId;
  final String? statusAnterior;
  final String statusNovo;
  final String? usuarioId;
  final String? observacao;
  final Map<String, dynamic>? dadosExtras;
  final DateTime createdAt;

  ObraMaterialHistorico({
    required this.id,
    required this.obraMaterialId,
    this.statusAnterior,
    required this.statusNovo,
    this.usuarioId,
    this.observacao,
    this.dadosExtras,
    required this.createdAt,
  });

  factory ObraMaterialHistorico.fromMap(Map<String, dynamic> map) {
    return ObraMaterialHistorico(
      id: map['id']?.toString() ?? '',
      obraMaterialId: map['obra_material_id']?.toString() ?? '',
      statusAnterior: map['status_anterior']?.toString(),
      statusNovo: map['status_novo']?.toString() ?? '',
      usuarioId: map['usuario_id']?.toString(),
      observacao: map['observacao']?.toString(),
      dadosExtras: map['dados_extras'] as Map<String, dynamic>?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'obra_material_id': obraMaterialId,
      'status_anterior': statusAnterior,
      'status_novo': statusNovo,
      'usuario_id': usuarioId,
      'observacao': observacao,
      'dados_extras': dadosExtras,
    };
  }

  String get statusNovoLabel => ObraMaterial.statusLabels[statusNovo] ?? statusNovo;
  String get statusAnteriorLabel =>
      statusAnterior != null ? (ObraMaterial.statusLabels[statusAnterior] ?? statusAnterior!) : '—';
}