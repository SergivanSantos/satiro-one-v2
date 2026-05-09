
// lib/utils/role_filter_helper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/employee_provider.dart';
import '../models/employee.dart';

class RoleFilterHelper {
  /// Retorna a lista de funcionários que o usuário atual tem permissão de ver
  static List<Employee> getVisibleEmployees(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final currentEmployee = employeeProvider.currentEmployee;

    if (currentEmployee == null) return [];

    // Super_rh ou super_admin → vê todas as filiais
    if (currentEmployee.role == 'super_rh' || currentEmployee.role == 'super_admin') {
      return employeeProvider.employees;
    }

    // Usuários normais (rh, gestor, etc.) → vê apenas sua própria filial
    final branchId = currentEmployee.branchId;
    if (branchId == null) return [];

    return employeeProvider.employees
        .where((e) => e.branchId == branchId)
        .toList();
  }

  /// Retorna se o usuário atual pode ver TODAS as filiais
  static bool canSeeAllBranches(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final current = employeeProvider.currentEmployee;
    return current?.role == 'super_rh' || current?.role == 'super_admin';
  }

  static bool isSuperUser(BuildContext context) {
    final employee = Provider.of<EmployeeProvider>(context, listen: false).currentEmployee;
    if (employee == null) return false;
    final role = employee.role?.toLowerCase() ?? '';
    return role.contains('super_') || role == 'admin' || role == 'super_rh';
  }

  /// Filtra uma lista de registros (time_entries, bank_hours, etc.)
  /// de acordo com a permissão do usuário
  static List<T> filterByVisibleEmployees<T>(
      BuildContext context,
      List<T> records,
      String Function(T) getEmployeeId, // função para pegar o employee_id do registro
      ) {
    final visibleEmployees = getVisibleEmployees(context);
    final visibleIds = visibleEmployees.map((e) => e.id).toSet();

    return records.where((record) {
      final empId = getEmployeeId(record);
      return visibleIds.contains(empId);
    }).toList();
  }
}