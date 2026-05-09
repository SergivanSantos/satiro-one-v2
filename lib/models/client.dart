// lib/models/client.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'attendment.dart';
import 'client_phase.dart';

enum ClientType { fisical, juridical }

enum WarrantyStatus {
  fullCoverage,
  laborCharged,
  noCoverage,
  notDeliveredYet,
}

class Client {
  final int? id;
  final ClientType type;
  final String name;
  final String? fantasyName;
  final String document;
  final String? stateRegistration;
  final String? municipalRegistration;
  final String cep;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String? obra;
  final String? contact;
  final String phone;
  final String? email;
  final int? architectId;
  final int? constructorId;
  final int? cityId;
  final DateTime? deliveryDate;
  final DateTime? birthDate;
  final String? branchId;

  // ==================== Fases da Obra ====================
  final List<ClientPhase> phases;

  // Campos de join
  final String? architectName;
  final String? constructorName;

  // Mantido para compatibilidade
  final List<Attendment> attendments;

  Client({
    this.id,
    required this.type,
    required this.name,
    this.fantasyName,
    required this.document,
    this.stateRegistration,
    this.municipalRegistration,
    this.cep = '',
    this.street = '',
    this.number = '',
    this.complement,
    this.neighborhood = '',
    this.city = '',
    this.state = '',
    this.obra,
    this.contact,
    this.phone = '',
    this.email,
    this.architectId,
    this.constructorId,
    this.cityId,
    this.deliveryDate,
    this.birthDate,
    this.branchId,
    this.phases = const [],
    this.attendments = const [],
    this.architectName,
    this.constructorName,
  });

  /// Factory para ler do Supabase
  factory Client.fromJson(Map<String, dynamic> json) {
    final phasesList = (json['phases'] as List<dynamic>?)
        ?.map((p) => ClientPhase.fromJson(p as Map<String, dynamic>))
        .toList() ??
        [];

    // Determina a fase atual (primeira com isCurrent = true ou a primeira fase)
    ClientPhase? currentPhase;
    if (phasesList.isNotEmpty) {
      currentPhase = phasesList.firstWhereOrNull((p) => p.isCurrent == true) ?? phasesList.first;
    }

    return Client(
      id: json['id'] as int?,
      type: ClientType.values.firstWhere(
            (e) => e.name == (json['type'] as String?),
        orElse: () => ClientType.fisical,
      ),
      name: json['name'] as String? ?? '',
      fantasyName: json['fantasyname'] as String?,
      document: json['document'] as String? ?? '',
      stateRegistration: json['stateregistration'] as String?,
      municipalRegistration: json['municipalregistration'] as String?,
      cep: json['cep'] as String? ?? '',
      street: json['street'] as String? ?? '',
      number: json['number'] as String? ?? '',
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      obra: json['obra'] as String?,
      contact: json['contact'] as String?,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      architectId: json['architectid'] as int?,
      constructorId: json['constructorid'] as int?,
      cityId: json['cityid'] as int?,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.tryParse(json['delivery_date'] as String)
          : null,
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'] as String)
          : null,
      branchId: json['branch_id'] as String?,
      phases: phasesList,
      attendments: [],

      architectName: json['architect']?['name'] as String?,
      constructorName: json['constructor']?['name'] as String?,
    );
  }

  /// Para salvar no Supabase (não inclui fases)
  Map<String, dynamic> toJson({bool excludeId = false}) {
    final map = {
      'type': type.name,
      'name': name,
      'fantasyname': fantasyName,
      'document': document,
      'stateregistration': stateRegistration,
      'municipalregistration': municipalRegistration,
      'cep': cep,
      'street': street,
      'number': number,
      'complement': complement,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'obra': obra,
      'contact': contact,
      'phone': phone,
      'email': email,
      'architectid': architectId,
      'constructorid': constructorId,
      'cityid': cityId,
      'delivery_date': deliveryDate?.toIso8601String(),
      'birth_date': birthDate?.toIso8601String(),
      'branch_id': branchId,
    };

    if (!excludeId && id != null) {
      map['id'] = id;
    }

    return map;
  }

  Client copyWith({
    int? id,
    ClientType? type,
    String? name,
    String? fantasyName,
    String? document,
    String? stateRegistration,
    String? municipalRegistration,
    String? cep,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
    String? obra,
    String? contact,
    String? phone,
    String? email,
    int? architectId,
    int? constructorId,
    int? cityId,
    DateTime? deliveryDate,
    DateTime? birthDate,
    String? branchId,
    List<ClientPhase>? phases,
    List<Attendment>? attendments,
    String? architectName,
    String? constructorName,
  }) {
    return Client(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      fantasyName: fantasyName ?? this.fantasyName,
      document: document ?? this.document,
      stateRegistration: stateRegistration ?? this.stateRegistration,
      municipalRegistration: municipalRegistration ?? this.municipalRegistration,
      cep: cep ?? this.cep,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
      obra: obra ?? this.obra,
      contact: contact ?? this.contact,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      architectId: architectId ?? this.architectId,
      constructorId: constructorId ?? this.constructorId,
      cityId: cityId ?? this.cityId,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      birthDate: birthDate ?? this.birthDate,
      branchId: branchId ?? this.branchId,
      phases: phases ?? this.phases,
      attendments: attendments ?? this.attendments,
      architectName: architectName ?? this.architectName,
      constructorName: constructorName ?? this.constructorName,
    );
  }

  // ====================== Garantia ======================
  WarrantyStatus get warrantyStatus {
    if (deliveryDate == null) return WarrantyStatus.notDeliveredYet;

    final now = DateTime.now();
    final endFull = DateTime(deliveryDate!.year, deliveryDate!.month + 3, deliveryDate!.day);
    final endWarranty = DateTime(deliveryDate!.year, deliveryDate!.month + 12, deliveryDate!.day);

    if (now.isBefore(endFull) || now.isAtSameMomentAs(endFull)) return WarrantyStatus.fullCoverage;
    if (now.isBefore(endWarranty) || now.isAtSameMomentAs(endWarranty)) return WarrantyStatus.laborCharged;
    return WarrantyStatus.noCoverage;
  }

  String get warrantyDescription {
    if (deliveryDate == null) return 'Obra ainda não entregue';

    final endFull = DateTime(deliveryDate!.year, deliveryDate!.month + 3, deliveryDate!.day);
    final endWarranty = DateTime(deliveryDate!.year, deliveryDate!.month + 12, deliveryDate!.day);

    switch (warrantyStatus) {
      case WarrantyStatus.fullCoverage:
        return 'Garantia total até ${DateFormat('dd/MM/yyyy').format(endFull)}';
      case WarrantyStatus.laborCharged:
        return 'Mão de obra cobrada até ${DateFormat('dd/MM/yyyy').format(endWarranty)}';
      case WarrantyStatus.noCoverage:
        return 'Fora do período de garantia';
      case WarrantyStatus.notDeliveredYet:
        return 'Obra ainda não entregue';
    }
  }

  Color get warrantyColor {
    switch (warrantyStatus) {
      case WarrantyStatus.fullCoverage: return Colors.green;
      case WarrantyStatus.laborCharged: return Colors.orange;
      case WarrantyStatus.noCoverage: return Colors.grey.shade700;
      case WarrantyStatus.notDeliveredYet: return Colors.blueGrey;
    }
  }

  String get birthDateFormatted => birthDate != null ? DateFormat('dd/MM').format(birthDate!) : '—';

  // ====================== Fases ======================
  // Getter para o ID da fase atual (usado nas abas)
  int? get currentPhaseId {
    final current = phases.firstWhereOrNull((p) => p.isCurrent == true);
    return current?.phaseConfigId;
  }

  String get currentPhaseName {
    final current = phases.firstWhereOrNull((p) => p.isCurrent == true);
    return current?.phaseName ?? 'Não iniciada';
  }

  Color get currentPhaseColor {
    final current = phases.firstWhereOrNull((p) => p.isCurrent == true);
    if (current == null) return Colors.grey;
    if (current.isCompleted) return Colors.green;
    return Colors.orange;
  }
}