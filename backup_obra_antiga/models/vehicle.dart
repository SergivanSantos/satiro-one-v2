// lib/models/vehicle.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Vehicle {
  final int? id;
  final String placa;
  final String modelo;
  final int? ano;
  final String? cor;
  final int? odometroInicial;
  final int? odometroDevolucao;
  final int? capacidade;
  final String? observacoes;
  final String status;
  final int? idTecnico;

  // Filial
  final String? branchId;
  final String? branchNome;

  // Franquia de KM
  final int? kmContratadoMensal;
  final int? kmInicialMesAtual;
  final String? mesAnoReferencia;

  // Datas de uso
  final DateTime? dataRetirada;
  final DateTime? dataDevolucao;

  Vehicle({
    this.id,
    required this.placa,
    required this.modelo,
    this.ano,
    this.cor,
    this.odometroInicial,
    this.odometroDevolucao,
    this.capacidade,
    this.observacoes,
    required this.status,
    this.idTecnico,
    this.branchId,
    this.branchNome,
    this.kmContratadoMensal,
    this.kmInicialMesAtual,
    this.mesAnoReferencia,
    this.dataRetirada,
    this.dataDevolucao,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int?,
      placa: json['placa'] as String? ?? '',
      modelo: json['modelo'] as String? ?? '',
      ano: json['ano'] is int ? json['ano'] as int? : int.tryParse(json['ano']?.toString() ?? ''),
      cor: json['cor'] as String?,
      odometroInicial: json['odometro_inicial'] is int ? json['odometro_inicial'] as int? : int.tryParse(json['odometro_inicial']?.toString() ?? ''),
      odometroDevolucao: json['odometro_devolucao'] is int ? json['odometro_devolucao'] as int? : int.tryParse(json['odometro_devolucao']?.toString() ?? ''),
      capacidade: json['capacidade'] is int ? json['capacidade'] as int? : int.tryParse(json['capacidade']?.toString() ?? ''),
      observacoes: json['observacoes'] as String?,
      status: json['status'] as String? ?? 'disponivel',
      idTecnico: json['id_tecnico'] is int ? json['id_tecnico'] as int? : int.tryParse(json['id_tecnico']?.toString() ?? ''),
      branchId: json['branch_id'] as String?,
      branchNome: json['branch']?['name'] as String?,
      kmContratadoMensal: json['km_contratado_mensal'] is int ? json['km_contratado_mensal'] as int? : int.tryParse(json['km_contratado_mensal']?.toString() ?? ''),
      kmInicialMesAtual: json['km_inicial_mes_atual'] is int ? json['km_inicial_mes_atual'] as int? : int.tryParse(json['km_inicial_mes_atual']?.toString() ?? ''),
      mesAnoReferencia: json['mes_ano_referencia'] as String?,
      dataRetirada: json['data_retirada'] != null ? DateTime.tryParse(json['data_retirada'] as String) : null,
      dataDevolucao: json['data_devolucao'] != null ? DateTime.tryParse(json['data_devolucao'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final df = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
    return {
      'id': id,
      'placa': placa,
      'modelo': modelo,
      'ano': ano,
      'cor': cor,
      'odometro_inicial': odometroInicial,
      'odometro_devolucao': odometroDevolucao,
      'capacidade': capacidade,
      'observacoes': observacoes,
      'status': status,
      'id_tecnico': idTecnico,
      'branch_id': branchId,
      'km_contratado_mensal': kmContratadoMensal,
      'km_inicial_mes_atual': kmInicialMesAtual,
      'mes_ano_referencia': mesAnoReferencia,
      'data_retirada': dataRetirada != null ? df.format(dataRetirada!.toUtc()) : null,
      'data_devolucao': dataDevolucao != null ? df.format(dataDevolucao!.toUtc()) : null,
    };
  }

  Vehicle copyWith({
    int? id,
    String? placa,
    String? modelo,
    int? ano,
    String? cor,
    int? odometroInicial,
    int? odometroDevolucao,
    int? capacidade,
    String? observacoes,
    String? status,
    int? idTecnico,
    String? branchId,
    String? branchNome,
    int? kmContratadoMensal,
    int? kmInicialMesAtual,
    String? mesAnoReferencia,
    DateTime? dataRetirada,
    DateTime? dataDevolucao,
  }) {
    return Vehicle(
      id: id ?? this.id,
      placa: placa ?? this.placa,
      modelo: modelo ?? this.modelo,
      ano: ano ?? this.ano,
      cor: cor ?? this.cor,
      odometroInicial: odometroInicial ?? this.odometroInicial,
      odometroDevolucao: odometroDevolucao ?? this.odometroDevolucao,
      capacidade: capacidade ?? this.capacidade,
      observacoes: observacoes ?? this.observacoes,
      status: status ?? this.status,
      idTecnico: idTecnico ?? this.idTecnico,
      branchId: branchId ?? this.branchId,
      branchNome: branchNome ?? this.branchNome,
      kmContratadoMensal: kmContratadoMensal ?? this.kmContratadoMensal,
      kmInicialMesAtual: kmInicialMesAtual ?? this.kmInicialMesAtual,
      mesAnoReferencia: mesAnoReferencia ?? this.mesAnoReferencia,
      dataRetirada: dataRetirada ?? this.dataRetirada,
      dataDevolucao: dataDevolucao ?? this.dataDevolucao,
    );
  }

  // ───────────────────────────────────────────────
  // Formatação de datas
  // ───────────────────────────────────────────────
  String formatDataRetirada() {
    return dataRetirada != null ? DateFormat('dd/MM/yyyy HH:mm').format(dataRetirada!.toLocal()) : '—';
  }

  String formatDataDevolucao() {
    return dataDevolucao != null ? DateFormat('dd/MM/yyyy HH:mm').format(dataDevolucao!.toLocal()) : '—';
  }

  // ───────────────────────────────────────────────
  // CÁLCULOS DE FRANQUIA COM LOGS PARA DEPURAÇÃO
  // ───────────────────────────────────────────────
  int get kmRodadoMesAtual {
    print('[DEBUG CALC] kmRodadoMesAtual chamado para veículo $id (placa $placa)');
    print('[DEBUG CALC]   kmInicialMesAtual = $kmInicialMesAtual');
    print('[DEBUG CALC]   odometroDevolucao = $odometroDevolucao');
    print('[DEBUG CALC]   status = $status');

    if (kmInicialMesAtual == null) {
      print('[DEBUG CALC]   → kmInicialMesAtual é null → rodado = 0');
      return 0;
    }

    if (odometroDevolucao != null) {
      final rodado = odometroDevolucao! - kmInicialMesAtual!;
      print('[DEBUG CALC]   → Veículo devolvido → rodado = $rodado km');
      return rodado;
    } else if (status == 'em_uso' && odometroInicial != null) {
      // Veículo em uso: usa o odômetro da retirada atual
      final rodado = odometroInicial! - kmInicialMesAtual!;
      print('[DEBUG CALC]   → Veículo em uso → rodado desde retirada = $rodado km');
      return rodado;
    }

    print('[DEBUG CALC]   → Nenhum dado suficiente → rodado = 0');
    return 0;
  }

  int get kmDisponivel {
    final rodado = kmRodadoMesAtual;
    final disponivel = (kmContratadoMensal ?? 0) - rodado;
    print('[DEBUG CALC] kmDisponivel = $disponivel km (contratado: ${kmContratadoMensal ?? 0} - rodado: $rodado)');
    return disponivel;
  }

  String get kmDisponivelFormatado {
    final disponivel = kmDisponivel;
    if (disponivel < 0) {
      return 'Excedido em ${disponivel.abs()} km';
    } else if (disponivel == 0) {
      return 'Franquia esgotada';
    }
    return '$disponivel km disponíveis';
  }

  double get percentualFranquiaUsada {
    if (kmContratadoMensal == null || kmContratadoMensal == 0) return 0.0;
    return (kmRodadoMesAtual / kmContratadoMensal!) * 100;
  }

  String get percentualFranquiaUsadaFormatado {
    return '${percentualFranquiaUsada.toStringAsFixed(1)}%';
  }

  Color get corKmDisponivel {
    final perc = percentualFranquiaUsada;
    if (perc >= 80) return Colors.red;
    if (perc >= 60) return Colors.orange;
    return Colors.green;
  }

  // Outros getters mantidos
  String get statusFormatado {
    switch (status.toLowerCase()) {
      case 'em_uso':
        return 'Em uso';
      case 'disponivel':
        return 'Disponível';
      case 'manutencao':
        return 'Manutenção';
      default:
        return status;
    }
  }

  String get filialDisplay {
    if (branchNome != null && branchNome!.isNotEmpty) return branchNome!;
    return branchId != null ? 'Filial (ID: $branchId)' : 'Sem filial';
  }

  @override
  String toString() {
    return 'Vehicle{id: $id, placa: $placa, modelo: $modelo, status: $status, '
        'branch: $branchNome ($branchId), kmContratado: $kmContratadoMensal, '
        'kmDisponivel: $kmDisponivel}';
  }
}