// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ParcelRule {
  final double maxValue;
  final int maxInstallments;
  ParcelRule(this.maxValue, this.maxInstallments);

  Map<String, dynamic> toJson() => {'maxValue': maxValue, 'maxInstallments': maxInstallments};
  factory ParcelRule.fromJson(Map<String, dynamic> json) =>
      ParcelRule(json['maxValue'], json['maxInstallments']);
}

class CompanyInfo {
  String name;
  String cnpj;
  String address;
  String phone;
  String? logoPath;

  CompanyInfo({
    required this.name,
    required this.cnpj,
    required this.address,
    required this.phone,
    this.logoPath,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'cnpj': cnpj,
    'address': address,
    'phone': phone,
    'logoPath': logoPath,
  };

  factory CompanyInfo.fromJson(Map<String, dynamic> json) => CompanyInfo(
    name: json['name'] ?? 'IVM Estoque',
    cnpj: json['cnpj'] ?? '',
    address: json['address'] ?? '',
    phone: json['phone'] ?? '',
    logoPath: json['logoPath'],
  );
}

class SettingsProvider with ChangeNotifier {
  static const String _keyHidePrices = 'hide_prices';
  static const String _keyParcelRules = 'parcel_rules';
  static const String _keyCompanyInfo = 'company_info';
  static const String _keyDarkMode = 'dark_mode';

  bool _hidePrices = false;
  List<ParcelRule> _parcelRules = [];
  CompanyInfo _companyInfo = CompanyInfo(name: 'IVM Estoque', cnpj: '', address: '', phone: '');
  bool _darkMode = false;

  SettingsProvider() {
    _loadSettings();
  }

  bool get hidePrices => _hidePrices;
  List<ParcelRule> get parcelRules => _parcelRules;
  CompanyInfo get companyInfo => _companyInfo;
  bool get darkMode => _darkMode;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _hidePrices = prefs.getBool(_keyHidePrices) ?? false;
    _darkMode = prefs.getBool(_keyDarkMode) ?? false;

    final rulesJson = prefs.getString(_keyParcelRules);
    if (rulesJson != null) {
      _parcelRules = (jsonDecode(rulesJson) as List)
          .map((e) => ParcelRule.fromJson(e))
          .toList();
    } else {
      // REGRAS PADRÃO
      _parcelRules = [
        ParcelRule(1000.0, 3),
        ParcelRule(3000.0, 6),
        ParcelRule(10000.0, 10),
        ParcelRule(double.infinity, 12),
      ];
    }

    final companyJson = prefs.getString(_keyCompanyInfo);
    if (companyJson != null) {
      _companyInfo = CompanyInfo.fromJson(jsonDecode(companyJson));
    }

    notifyListeners();
  }

  Future<void> setHidePrices(bool value) async {
    _hidePrices = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHidePrices, value);
    notifyListeners();
  }

  Future<void> setParcelRules(List<ParcelRule> rules) async {
    _parcelRules = rules;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyParcelRules, jsonEncode(rules.map((r) => r.toJson()).toList()));
    notifyListeners();
  }

  Future<void> setCompanyInfo(CompanyInfo info) async {
    _companyInfo = info;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCompanyInfo, jsonEncode(info.toJson()));
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    notifyListeners();
  }

  int getMaxInstallments(double totalValue) {
    for (final rule in _parcelRules) {
      if (totalValue <= rule.maxValue) return rule.maxInstallments;
    }
    return 12;
  }
}