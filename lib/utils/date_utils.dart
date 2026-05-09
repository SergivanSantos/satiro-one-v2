// lib/utils/date_utils.dart
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Inicializa formatação de datas para pt_BR (chamar uma vez no main)
Future<void> initializeAppDateFormatting() async {
  await initializeDateFormatting('pt_BR', null);
}

/// Formata datas vindas do Supabase (UTC → local, formato brasileiro)
String formatSupabaseDate(
    String? isoDate, {
      String pattern = 'dd/MM/yy HH:mm',
      String locale = 'pt_BR',
      String fallback = 'Não informado',
    }) {
  if (isoDate == null || isoDate.isEmpty) return fallback;
  try {
    final dateUtc = DateTime.parse(isoDate).toUtc();
    final dateLocal = dateUtc.toLocal();
    return DateFormat(pattern, locale).format(dateLocal);
  } catch (e) {
    print('Erro ao formatar data: $e - Valor: $isoDate');
    return fallback;
  }
}