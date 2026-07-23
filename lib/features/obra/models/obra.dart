// lib/features/obra/models/obra.dart
import 'package:flutter/material.dart';

class Obra {
  final String id;
  final String nome;
  final String? clienteId;
  final String? filialId;
  final String? arquitetoId;
  final String? construtoraId;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String status;
  final bool usaFases;

  // === RESPONSÁVEL DA OBRA ===
  final String? responsavelNome;
  final String? responsavelContato;

  // === ENDEREÇO DA OBRA (NOVO) ===
  final String? rua;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? complemento;

  // === CAMPOS PARA CONTROLE DE FASE ===
  final String? faseAtualId;
  final String? faseAtualNome;
  final DateTime? dataUltimaMudancaFase;
  final String? responsavelUltimaMudanca;

  // === DATAS DO CRONOGRAMA DA FASE ATUAL ===
  final DateTime? dataInicioPrevistaFase;
  final DateTime? dataFimPrevistaFase;
  final DateTime? dataInicioRealFase;
  final DateTime? dataFimRealFase;

  Obra({
    required this.id,
    required this.nome,
    this.clienteId,
    this.filialId,
    this.arquitetoId,
    this.construtoraId,
    this.dataInicio,
    this.dataFim,
    this.status = 'em_andamento',
    this.usaFases = false,
    this.responsavelNome,
    this.responsavelContato,
    this.rua,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.complemento,
    this.faseAtualId,
    this.faseAtualNome,
    this.dataUltimaMudancaFase,
    this.responsavelUltimaMudanca,
    this.dataInicioPrevistaFase,
    this.dataFimPrevistaFase,
    this.dataInicioRealFase,
    this.dataFimRealFase,
  });

  factory Obra.fromMap(Map<String, dynamic> map) {
    final faseAtualId = map['fase_atual_id']?.toString();

    final obraFaseList = map['obra_fase'] as List<dynamic>? ?? [];

    Map<String, dynamic>? obraFaseAtual;

    for (var item in obraFaseList) {
      if (item is Map<String, dynamic>) {
        final faseIdDoItem = item['fase_id']?.toString();
        if (faseIdDoItem == faseAtualId) {
          obraFaseAtual = item;
          break;
        }
      }
    }

    if (obraFaseAtual == null && obraFaseList.isNotEmpty) {
      obraFaseAtual = obraFaseList.first as Map<String, dynamic>?;
    }

    return Obra(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      clienteId: map['cliente_id']?.toString(),
      filialId: map['filial_id']?.toString(),
      arquitetoId: map['arquiteto_id']?.toString(),
      construtoraId: map['construtora_id']?.toString(),
      dataInicio: map['data_inicio'] != null ? DateTime.tryParse(map['data_inicio'].toString()) : null,
      dataFim: map['data_fim'] != null ? DateTime.tryParse(map['data_fim'].toString()) : null,
      status: (map['status']?.toString() ?? 'em_andamento').toLowerCase(),
      usaFases: map['usa_fases'] == true || map['usa_fases'] == 'true' || map['usa_fases'] == 1,

      responsavelNome: map['responsavel_nome']?.toString(),
      responsavelContato: map['responsavel_contato']?.toString(),

      rua: map['rua']?.toString(),
      numero: map['numero']?.toString(),
      bairro: map['bairro']?.toString(),
      cidade: map['cidade']?.toString(),
      estado: map['estado']?.toString(),
      complemento: map['complemento']?.toString(),

      faseAtualId: faseAtualId,
      faseAtualNome: map['fase_atual']?['nome']?.toString() ?? map['fase_atual_nome']?.toString(),

      dataUltimaMudancaFase: map['data_ultima_mudanca_fase'] != null
          ? DateTime.tryParse(map['data_ultima_mudanca_fase'].toString())
          : null,
      responsavelUltimaMudanca: map['responsavel_ultima_mudanca']?.toString(),

      dataInicioPrevistaFase: obraFaseAtual?['data_inicio_prevista'] != null
          ? DateTime.tryParse(obraFaseAtual!['data_inicio_prevista'].toString())
          : null,
      dataFimPrevistaFase: obraFaseAtual?['data_fim_prevista'] != null
          ? DateTime.tryParse(obraFaseAtual!['data_fim_prevista'].toString())
          : null,
      dataInicioRealFase: obraFaseAtual?['data_inicio_real'] != null
          ? DateTime.tryParse(obraFaseAtual!['data_inicio_real'].toString())
          : null,
      dataFimRealFase: obraFaseAtual?['data_fim_real'] != null
          ? DateTime.tryParse(obraFaseAtual!['data_fim_real'].toString())
          : null,
    );
  }

  String get faseAtualDisplay => faseAtualNome?.isNotEmpty == true
      ? faseAtualNome!
      : status.toUpperCase();

  // ==================== STATUS INTELIGENTE DO CRONOGRAMA ====================
  String get statusCronograma {
    if (dataFimPrevistaFase == null) return "Sem prazo definido";

    if (dataFimRealFase != null) {
      return "Concluído";
    }

    final hoje = DateTime.now();
    final diasRestantes = dataFimPrevistaFase!.difference(hoje).inDays;

    if (diasRestantes < 0) {
      return "Atrasado (${-diasRestantes}d)";
    } else if (diasRestantes <= 10) {           // ← Alterado para 10 dias
      return "Urgente (${diasRestantes}d)";
    } else {
      return "No Prazo (${diasRestantes}d)";
    }

  }

  Color get corCronograma {
    if (dataFimRealFase != null) return Colors.green;
    if (dataFimPrevistaFase == null) return Colors.grey;

    final diasRestantes = dataFimPrevistaFase!.difference(DateTime.now()).inDays;

    if (diasRestantes < 0) return Colors.red;
    if (diasRestantes <= 10) return Colors.deepOrange;   // ← Alterado para 10 dias
    return Colors.orange;
  }

  String? get responsavelWhatsApp {
    if (responsavelContato == null) return null;
    final clean = responsavelContato!.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length >= 10 ? clean : null;
  }

  // Endereço completo formatado
  String get enderecoCompleto {
    final parts = <String>[];
    if (rua != null) parts.add(rua!);
    if (numero != null) parts.add(numero!);
    if (bairro != null) parts.add(bairro!);
    if (cidade != null) parts.add(cidade!);
    if (estado != null) parts.add(estado!);
    if (complemento != null && complemento!.isNotEmpty) parts.add("($complemento)");

    return parts.isEmpty ? 'Endereço não cadastrado' : parts.join(', ');
  }
}