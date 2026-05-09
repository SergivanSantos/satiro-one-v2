import '../models/employee.dart';

class WorkHoursCalculator {

  static double getDailyHours(Employee employee, DateTime date) {
    final type = employee.workScheduleType ?? 'standard_9x8';

    // Padrão antigo (compatibilidade)
    if (type == 'standard_9x8') {
      if (date.weekday == 5) return 8.0;        // Sexta
      if (date.weekday >= 1 && date.weekday <= 4) return 9.0; // Seg a Qui
      return 0.0; // Sábado e Domingo = 0 (só aparece se bater ponto)
    }

    // Nova lógica flexível
    return employee.dailyWorkHours ?? 8.0;
  }

  static bool shouldShowDay(Employee employee, DateTime date) {
    final type = employee.workScheduleType ?? 'standard_9x8';

    if (type == 'standard_9x8') {
      // Sábado e Domingo só aparecem se tiver registro
      if (date.weekday == 6 || date.weekday == 7) {
        return false; // Será mostrado só se tiver ponto batido
      }
      return true;
    }

    // Para outros tipos, usa workDaysOfWeek
    final allowedDays = employee.workDaysOfWeek ?? [1,2,3,4,5];
    return allowedDays.contains(date.weekday);
  }
}