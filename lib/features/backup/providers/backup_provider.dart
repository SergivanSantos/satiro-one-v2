// lib/features/backup/providers/backup_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackupProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _backups = [];
  List<Map<String, dynamic>> get backups => _backups;

  List<Map<String, dynamic>> _allBackups = [];
  List<Map<String, dynamic>> get allBackups => _allBackups;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ==================== BACKUP ====================

  Future<bool> fazerBackupObra(String obraId, {String tipo = 'manual'}) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint("💾 Iniciando backup completo da obra: $obraId");

      // Obra principal
      final obraPrincipal = await _supabase
          .from('obra')
          .select()
          .eq('id', obraId)
          .single();

      // Ambientes + Serviços
      final ambientes = await _supabase
          .from('obra_ambiente')
          .select('*, obra_servico(*)')
          .eq('obra_id', obraId)
          .filter('deleted_at', 'is', null);

      final backupData = {
        'obra_id': obraId,
        'timestamp': DateTime.now().toIso8601String(),
        'tipo_backup': tipo,
        'obra_principal': obraPrincipal,
        'total_ambientes': ambientes.length,
        'ambientes': ambientes,
      };

      await _supabase.from('obra_backup').insert({
        'obra_id': obraId,
        'tipo': tipo,
        'dados': backupData,
      });

      debugPrint("✅ Backup completo criado! (${ambientes.length} ambientes)");
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao criar backup: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== LISTAGEM ====================

  Future<void> listarBackups(String obraId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _supabase
          .from('obra_backup')
          .select()
          .eq('obra_id', obraId)
          .order('created_at', ascending: false);

      _backups = List.from(res);
      debugPrint("📋 ${_backups.length} backups carregados para a obra");
    } catch (e) {
      debugPrint("❌ Erro ao listar backups: $e");
      _backups = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> listarTodosBackups() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _supabase
          .from('obra_backup')
          .select()
          .order('created_at', ascending: false);

      _allBackups = List.from(res);
      debugPrint("📋 ${_allBackups.length} backups totais carregados");
    } catch (e) {
      debugPrint("❌ Erro ao listar todos backups: $e");
      _allBackups = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== RESTAURAÇÃO ====================

  Future<bool> restaurarBackup(String backupId) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint("🔄 Iniciando restauração do backup: $backupId");

      final backupRes = await _supabase
          .from('obra_backup')
          .select()
          .eq('id', backupId)
          .single();

      final data = backupRes['dados'] as Map<String, dynamic>;
      final originalObraId = data['obra_id'] as String;
      final obraPrincipal = data['obra_principal'] as Map<String, dynamic>?;
      final ambientesBackup = data['ambientes'] as List<dynamic>;

      debugPrint("📦 Restaurando obra + ${ambientesBackup.length} ambientes");

      // Verifica se a obra existe
      final obraExiste = await _supabase
          .from('obra')
          .select('id')
          .eq('id', originalObraId)
          .maybeSingle();

      String obraIdParaUsar = originalObraId;

      if (obraExiste == null && obraPrincipal != null) {
        debugPrint("⚠️ Obra original excluída. Recriando...");

        var novaObraData = Map<String, dynamic>.from(obraPrincipal);
        novaObraData.remove('id');
        novaObraData['status'] = novaObraData['status'] ?? 'em_andamento';

        final novaObra = await _supabase
            .from('obra')
            .insert(novaObraData)
            .select()
            .single();

        obraIdParaUsar = novaObra['id'];
        debugPrint("✅ Obra recriada: $obraIdParaUsar");
      }

      // Remove dados atuais
      await _supabase.from('obra_servico').delete().eq('obra_id', obraIdParaUsar);
      await _supabase.from('obra_ambiente').delete().eq('obra_id', obraIdParaUsar);

      // Restaura ambientes e serviços
      for (var amb in ambientesBackup) {
        final ambienteData = Map<String, dynamic>.from(amb);
        final servicos = ambienteData.remove('obra_servico') as List<dynamic>? ?? [];

        ambienteData['obra_id'] = obraIdParaUsar;

        final novoAmbiente = await _supabase
            .from('obra_ambiente')
            .insert(ambienteData)
            .select()
            .single();

        final novoAmbienteId = novoAmbiente['id'];

        for (var serv in servicos) {
          final servicoData = Map<String, dynamic>.from(serv);
          servicoData['ambiente_id'] = novoAmbienteId;
          servicoData['obra_id'] = obraIdParaUsar;
          servicoData.remove('id');

          await _supabase.from('obra_servico').insert(servicoData);
        }
      }

      debugPrint("✅ Restauração completa concluída!");
      return true;
    } catch (e) {
      debugPrint("❌ Erro ao restaurar backup: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}