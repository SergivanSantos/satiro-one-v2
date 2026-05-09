// lib/providers/ponto_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PontoProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _registrosHoje = [];
  bool _isLoading = false;

  RealtimeChannel? _subscription;

  List<Map<String, dynamic>> get registrosHoje => _registrosHoje;
  bool get isLoading => _isLoading;

  // ==================== GETTERS PARA HOJE ====================
  bool get jaBateuEntradaHoje => _registrosHoje.any((r) => r['entry_type'] == 'entrada');
  String? get horarioEntradaHoje => _getHorario('entrada');

  bool get jaBateuSaidaAlmocoHoje => _registrosHoje.any((r) => r['entry_type'] == 'saida_almoco');
  String? get horarioSaidaAlmocoHoje => _getHorario('saida_almoco');

  bool get jaBateuRetornoAlmocoHoje => _registrosHoje.any((r) => r['entry_type'] == 'retorno_almoco');
  String? get horarioRetornoAlmocoHoje => _getHorario('retorno_almoco');

  bool get jaBateuSaidaHoje => _registrosHoje.any((r) => r['entry_type'] == 'saida');
  String? get horarioSaidaHoje => _getHorario('saida');

  String? _getHorario(String type) {
    final registro = _registrosHoje.where((r) => r['entry_type'] == type).firstOrNull;
    if (registro == null) return null;

    final localTime = registro['timestamp_local'] as DateTime?;
    return localTime != null ? DateFormat('HH:mm').format(localTime) : null;
  }

  // ==================== CARREGAR REGISTROS DE HOJE (CORRIGIDO) ====================
  Future<void> carregarRegistrosHoje(int employeeId) async {
    _isLoading = true;
    notifyListeners();

    print('[PONTO PROVIDER] Iniciando carregarRegistrosHoje para employeeId: $employeeId');

    try {
      // Usa data LOCAL para definir o dia
      final agoraLocal = DateTime.now().toLocal();
      final inicioDoDiaLocal = DateTime(agoraLocal.year, agoraLocal.month, agoraLocal.day, 0, 0, 0);
      final fimDoDiaLocal = DateTime(agoraLocal.year, agoraLocal.month, agoraLocal.day, 23, 59, 59);

      // Converte para UTC para a consulta no banco
      final inicioUTC = inicioDoDiaLocal.toUtc().toIso8601String();
      final fimUTC = fimDoDiaLocal.toUtc().toIso8601String();

      print('[PONTO PROVIDER] Buscando registros do dia local: ${DateFormat('yyyy-MM-dd').format(agoraLocal)}');
      print('[PONTO PROVIDER] Range UTC: $inicioUTC até $fimUTC');

      final response = await Supabase.instance.client
          .from('time_entries')
          .select('entry_type, timestamp, latitude, longitude, accuracy')
          .eq('employee_id', employeeId)
          .gte('timestamp', inicioUTC)
          .lte('timestamp', fimUTC)
          .order('timestamp', ascending: true);

      _registrosHoje = response.map((r) {
        final utcTime = DateTime.parse(r['timestamp'] as String);
        return {
          ...r,
          'timestamp_local': utcTime.toLocal(),
        };
      }).toList();

      print('[PONTO PROVIDER] Carregou ${_registrosHoje.length} registros de hoje (sucesso!)');

      _escutarRealTime(employeeId);
    } catch (e) {
      print('[PONTO PROVIDER] Erro ao carregar registros de hoje: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== CARREGAR REGISTROS DE UMA DATA ESPECÍFICA ====================
  Future<void> carregarRegistrosPorData(int employeeId, DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dataStr = DateFormat('yyyy-MM-dd').format(date);

      final inicioDoDia = DateTime(date.year, date.month, date.day, 0, 0, 0).toUtc().toIso8601String();
      final fimDoDia = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();

      print('[PONTO PROVIDER] Buscando registros da data: $dataStr');

      final response = await Supabase.instance.client
          .from('time_entries')
          .select('entry_type, timestamp, latitude, longitude, accuracy')
          .eq('employee_id', employeeId)
          .gte('timestamp', inicioDoDia)
          .lte('timestamp', fimDoDia)
          .order('timestamp', ascending: true);

      _registrosHoje = response.map((r) {
        final utcTime = DateTime.parse(r['timestamp'] as String);
        return {
          ...r,
          'timestamp_local': utcTime.toLocal(),
        };
      }).toList();

      print('[PONTO PROVIDER] Carregou ${_registrosHoje.length} registros da data $dataStr');
    } catch (e) {
      print('[PONTO PROVIDER] Erro ao carregar registros por data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== ADICIONAR REGISTRO LOCAL ====================
  void adicionarRegistroLocal(String type, DateTime timestampUtc) {
    final localTime = timestampUtc.toLocal();
    _registrosHoje.add({
      'entry_type': type,
      'timestamp_utc': timestampUtc.toIso8601String(),
      'timestamp_local': localTime,
    });
    notifyListeners();
  }

  // ==================== REAL-TIME ====================
  void _escutarRealTime(int employeeId) {
    _subscription?.unsubscribe();

    _subscription = Supabase.instance.client
        .channel('time_entries_changes')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'time_entries',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'employee_id',
        value: employeeId,
      ),
      callback: (payload) {
        print('[PONTO PROVIDER] Novo ponto recebido via realtime');
        carregarRegistrosHoje(employeeId);
      },
    )
        .subscribe();
  }

  void limparRegistros() {
    _registrosHoje.clear();
    _subscription?.unsubscribe();
    _subscription = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}