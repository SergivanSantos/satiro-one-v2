import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import '../../providers/branch_provider.dart';
import '../../utils/role_filter_helper.dart';
import 'bank_hours_detail_screen.dart';

class BankHoursScreen extends StatefulWidget {
  const BankHoursScreen({super.key});

  @override
  State<BankHoursScreen> createState() => _BankHoursScreenState();
}

class _BankHoursScreenState extends State<BankHoursScreen> {
  List<Map<String, dynamic>> employeeBalances = [];
  bool loading = true;

  // Filtro de filial (apenas para super users)
  String? selectedBranchId;   // null = todas as filiais

  @override
  void initState() {
    super.initState();
    _loadAllEmployeesBalances();
  }

  Future<void> _loadAllEmployeesBalances() async {
    setState(() => loading = true);
    print('🔄 [BANK_HOURS_LIST] Iniciando carregamento com filtro de filial: ${selectedBranchId ?? "Todas"}');

    try {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final branchProvider = Provider.of<BranchProvider>(context, listen: false);

      List<Employee> visibleEmployees = RoleFilterHelper.getVisibleEmployees(context);

      if (selectedBranchId != null && RoleFilterHelper.canSeeAllBranches(context)) {
        visibleEmployees = visibleEmployees.where((e) => e.branchId == selectedBranchId).toList();
        print('🔍 [BANK_HOURS_LIST] Filtrado por filial específica: $selectedBranchId → ${visibleEmployees.length} funcionários');
      } else {
        print('🔍 [BANK_HOURS_LIST] Mostrando ${visibleEmployees.length} funcionários visíveis');
      }

      List<Map<String, dynamic>> result = [];
      int totalSum = 0;

      for (var emp in visibleEmployees) {
        if (emp.id == null) continue;

        final res = await Supabase.instance.client
            .from('bank_hours')
            .select('balance, month_year')
            .eq('employee_id', emp.id!);

        int acumulado = 0;
        int atual = 0;
        final now = DateTime.now();
        final currentMonthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';

        for (var row in res) {
          final balance = row['balance'] as int? ?? 0;
          final monthYear = row['month_year'] as String;

          if (monthYear == currentMonthYear) {
            atual = balance;
          } else {
            acumulado += balance;
          }
        }

        String branchName = 'Sem filial';
        if (emp.branchId != null) {
          for (var b in branchProvider.branches) {
            if (b.id == emp.branchId) {
              branchName = b.name ?? 'Filial ${emp.branchId}';
              break;
            }
          }
        }

        final employeeTotal = acumulado + atual;
        totalSum += employeeTotal;

        result.add({
          'employee': emp,
          'accumulated': acumulado,
          'currentMonth': atual,
          'total': employeeTotal,
          'branchName': branchName,
        });
      }

      setState(() => employeeBalances = result);
      print('✅ [BANK_HOURS_LIST] Lista carregada com ${result.length} funcionários | Somatório total: $totalSum minutos');
    } catch (e) {
      print('❌ [BANK_HOURS_LIST] Erro ao carregar saldos: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSeeAll = RoleFilterHelper.canSeeAllBranches(context);
    final branchProvider = Provider.of<BranchProvider>(context);

    // Calcula o somatório total atual
    final totalSum = employeeBalances.fold<int>(0, (sum, item) => sum + (item['total'] as int));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Banco de Horas - RH'),
            const Spacer(),
            // Contador total (alinhado com o título)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${totalSum ~/ 60}h ${(totalSum % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Seletor de filial (apenas para super users)
          if (canSeeAll)
            Container(
              width: 180,
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButton<String?>(
                value: selectedBranchId,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                dropdownColor: Colors.teal[100],
                style: const TextStyle(color: Colors.black),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas as filiais')),
                  ...branchProvider.branches.map((b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(b.name ?? b.id, overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: (value) {
                  print('🔄 [BANK_HOURS_LIST] Filial selecionada na AppBar: ${value ?? "Todas"}');
                  setState(() => selectedBranchId = value);
                  _loadAllEmployeesBalances();
                },
              ),
            ),

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllEmployeesBalances,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : employeeBalances.isEmpty
          ? const Center(child: Text('Nenhum funcionário encontrado'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: employeeBalances.length,
        itemBuilder: (context, index) {
          final item = employeeBalances[index];
          final emp = item['employee'] as Employee;
          final total = item['total'] as int;
          final branchName = item['branchName'] as String;

          return Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.70,
              child: Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[100],
                    child: Text(emp.name?.substring(0, 1) ?? '?',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(emp.name ?? 'Funcionário',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(branchName),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${total ~/ 60}h ${(total % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: total >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const Text('Saldo Total', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BankHoursDetailScreen(employee: emp),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}