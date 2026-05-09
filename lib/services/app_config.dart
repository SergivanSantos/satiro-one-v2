// lib/services/app_config.dart
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  bool _hidePrices = false;
  bool get hidePrices => _hidePrices;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _hidePrices = prefs.getBool('hide_prices') ?? false;
  }

  Future<void> setHidePrices(bool value) async {
    _hidePrices = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_prices', value);
  }
}