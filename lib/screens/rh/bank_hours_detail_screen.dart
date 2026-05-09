import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/employee.dart';

class BankHoursDetailScreen extends StatefulWidget {
  final Employee employee;

  const BankHoursDetailScreen({super.key, required this.employee});

  @override
  State<BankHoursDetailScreen> createState() => _BankHoursDetailScreenState();
}

class _BankHoursDetailScreenState extends State<BankHoursDetailScreen> {
  List<Map<String, dynamic>> movements = [];
  int accumulatedSyncMinutes = 0;
  int accumulatedManualMinutes = 0;
  int currentMonthSyncMinutes = 0;
  int currentMonthManualMinutes = 0;
  bool loading = true;

  final String _adminPassword = "123456";   // Senha temporária - altere depois

  @override
  void initState() {
    super.initState();
    print('🔄 [DETAIL] initState chamado para funcionário ${widget.employee.id}');
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    print('🔄 [DETAIL] Iniciando carregamento completo do funcionário ${widget.employee.id}');
    setState(() => loading = true);

    try {
      final employeeId = widget.employee.id!;

      final resMov = await Supabase.instance.client
          .from('bank_hours_movements')
          .select('id, minutes, type, description, movement_date')
          .eq('employee_id', employeeId)
          .order('movement_date', ascending: false);

      movements = List<Map<String, dynamic>>.from(resMov);
      print('📋 [DETAIL] Movimentações carregadas: ${movements.length} registros');

      final now = DateTime.now();
      final currentMonthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final resBalance = await Supabase.instance.client
          .from('bank_hours')
          .select('balance, month_year')
          .eq('employee_id', employeeId);

      int acumuladoFromBalance = 0;
      for (var row in resBalance) {
        final balance = row['balance'] as int? ?? 0;
        final monthYear = row['month_year'] as String;
        if (monthYear != currentMonthYear) acumuladoFromBalance += balance;
      }

      int acumuladoSync = 0;
      int acumuladoManual = 0;
      int currentSync = 0;
      int currentManual = 0;

      for (var m in movements) {
        final minutes = m['minutes'] as int;
        final description = (m['description'] as String? ?? '').toLowerCase();
        final movementMonth = (m['movement_date'] as String).substring(0, 7);
        final sign = (m['type'] as String) == 'credit' ? 1 : -1;
        final isSync = description.contains('sincronizadas do ponto');

        if (movementMonth == currentMonthYear) {
          if (isSync) currentSync += minutes * sign;
          else currentManual += minutes * sign;
        } else {
          if (isSync) acumuladoSync += minutes * sign;
          else acumuladoManual += minutes * sign;
        }
      }

      accumulatedSyncMinutes = acumuladoSync;
      accumulatedManualMinutes = acumuladoManual;
      currentMonthSyncMinutes = currentSync;
      currentMonthManualMinutes = currentManual;

      print('✅ [DETAIL] Saldos → Acumulado (Ponto): $acumuladoSync | Manual: $acumuladoManual | Total: ${acumuladoSync + acumuladoManual}');

    } catch (e) {
      print('❌ [DETAIL] Erro ao carregar dados: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accumulatedTotal = accumulatedSyncMinutes + accumulatedManualMinutes;
    final currentMonthTotal = currentMonthSyncMinutes + currentMonthManualMinutes;
    final grandTotal = accumulatedTotal + currentMonthTotal;

    return Scaffold(
      appBar: AppBar(title: Text(widget.employee.name ?? 'Banco de Horas')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildAccumulatedCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildMonthCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildSmallCard('Saldo Total', grandTotal, grandTotal >= 0 ? Colors.green : Colors.red, isTotal: true)),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Movimentações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (movements.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Nenhuma movimentação'))),

            ...movements.map((m) {
              final type = m['type'] as String;
              final minutes = m['minutes'] as int;
              final date = DateFormat('dd/MM/yyyy').format(DateTime.parse(m['movement_date']));
              final description = m['description'] as String? ?? '';
              final isSync = description.toLowerCase().contains('sincronizadas do ponto');
              final id = m['id'];

              String label = type == 'credit' ? '+' : '-';
              label += ' ${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: Icon(type == 'credit' ? Icons.add_circle : Icons.remove_circle, color: type == 'credit' ? Colors.green : Colors.red),
                  title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date),
                      if (description.isNotEmpty) Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: isSync
                      ? const Text('Sincronizado', style: TextStyle(fontSize: 12, color: Colors.blue))
                      : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteManualMovement(id, description),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'sync',
            onPressed: _syncPointToBankHours,
            icon: const Icon(Icons.sync),
            label: const Text('Sincronizar Ponto'),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => _requestPasswordForNewMovement(),
            icon: const Icon(Icons.add),
            label: const Text('Novo Lançamento'),
            backgroundColor: Colors.teal,
          ),
        ],
      ),
    );
  }

  // ==================== CARDS ====================
  Widget _buildAccumulatedCard() {
    final syncH = (accumulatedSyncMinutes.abs() / 60).floor();
    final syncM = accumulatedSyncMinutes.abs() % 60;
    final manualH = (accumulatedManualMinutes.abs() / 60).floor();
    final manualM = accumulatedManualMinutes.abs() % 60;
    final total = accumulatedSyncMinutes + accumulatedManualMinutes;
    final totalH = (total.abs() / 60).floor();
    final totalM = total.abs() % 60;
    final totalSign = total >= 0 ? '' : '-';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Acumulado', style: TextStyle(fontSize: 13)),
            Text('$totalSign$totalH h $totalM min', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 8),
            Text('Ponto: $syncH h $syncM min', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Manual: $manualH h $manualM min', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard() {
    final syncH = (currentMonthSyncMinutes.abs() / 60).floor();
    final syncM = currentMonthSyncMinutes.abs() % 60;
    final manualH = (currentMonthManualMinutes.abs() / 60).floor();
    final manualM = currentMonthManualMinutes.abs() % 60;
    final total = currentMonthSyncMinutes + currentMonthManualMinutes;
    final totalH = (total.abs() / 60).floor();
    final totalM = total.abs() % 60;
    final totalSign = total >= 0 ? '' : '-';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Mês Atual', style: TextStyle(fontSize: 13)),
            Text('$totalSign$totalH h $totalM min', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            Text('Ponto: $syncH h $syncM min', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Manual: $manualH h $manualM min', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(String title, int value, Color color, {bool isTotal = false}) {
    final hours = (value.abs() / 60).floor();
    final minutes = value.abs() % 60;
    final sign = value >= 0 ? '' : '-';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 13)),
            Text('$sign$hours h $minutes min', style: TextStyle(fontSize: isTotal ? 26 : 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // ==================== MÉTODOS QUE VOCÊ ENVIOU (100% intactos) ====================
  Future<void> _syncPointToBankHours() async {
    final now = DateTime.now();
    final maxPastDate = now.subtract(const Duration(days: 40));

    DateTime startDate = DateTime(now.year, now.month, 1);
    if (startDate.isBefore(maxPastDate)) {
      startDate = maxPastDate;
    }
    DateTime endDate = now;

    print('🔄 [SYNC] Abrindo seletor de período - Início sugerido: ${DateFormat('dd/MM/yyyy').format(startDate)}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Sincronizar Ponto', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Atenção:\n\n'
                    '• Só é permitido sincronizar os últimos 40 dias.\n'
                    '• Períodos mais antigos já foram consolidados para pagamento e não devem ser alterados.\n'
                    '• Recomendamos sincronizar apenas o mês atual.',
                style: TextStyle(fontSize: 14, color: Colors.orange, height: 1.5),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Início'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: startDate,
                    firstDate: maxPastDate,
                    lastDate: endDate,
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) {
                    if (picked.isBefore(maxPastDate)) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Não é permitido sincronizar datas com mais de 40 dias.'), backgroundColor: Colors.red),
                      );
                    } else {
                      setDialogState(() => startDate = picked);
                    }
                  }
                },
              ),
              ListTile(
                title: const Text('Fim'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(endDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: endDate,
                    firstDate: startDate,
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) setDialogState(() => endDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sincronizar')),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    if (startDate.isBefore(maxPastDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Período inválido. Não é permitido sincronizar datas com mais de 40 dias.'), backgroundColor: Colors.red),
      );
      return;
    }

    print('✅ [SYNC] Período confirmado: ${DateFormat('dd/MM/yyyy').format(startDate)} a ${DateFormat('dd/MM/yyyy').format(endDate)}');

    setState(() => loading = true);

    try {
      final employeeId = widget.employee.id!;

      await Supabase.instance.client
          .from('bank_hours_movements')
          .delete()
          .eq('employee_id', employeeId)
          .like('description', 'Horas extras sincronizadas do ponto - %')
          .gte('movement_date', DateFormat('yyyy-MM-dd').format(startDate))
          .lte('movement_date', DateFormat('yyyy-MM-dd').format(endDate));

      print('🗑️ [SYNC] Lançamentos antigos de sincronização removidos do período');

      final res = await Supabase.instance.client
          .from('time_entries')
          .select('entry_type, timestamp, observations')
          .eq('employee_id', employeeId)
          .gte('timestamp', '${DateFormat('yyyy-MM-dd').format(startDate)} 00:00:00')
          .lte('timestamp', '${DateFormat('yyyy-MM-dd').format(endDate)} 23:59:59')
          .order('timestamp');

      final records = List<Map<String, dynamic>>.from(res);
      print('📥 [SYNC] Registros de ponto encontrados: ${records.length}');

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var r in records) {
        final ts = DateTime.parse(r['timestamp']).toLocal();
        final dateKey = DateFormat('yyyy-MM-dd').format(ts);
        grouped.putIfAbsent(dateKey, () => []);
        grouped[dateKey]!.add(r);
      }

      int totalSynced = 0;

      for (var dateKey in grouped.keys) {
        final dayRecords = grouped[dateKey]!;

        final extraStr = _calculateExtraHours(dayRecords);
        if (extraStr == '0 min') continue;

        final parts = extraStr.split(' ');
        final sign = extraStr.startsWith('-') ? -1 : 1;
        final h = int.tryParse(parts[0].replaceAll('-', '')) ?? 0;
        final m = int.tryParse(parts[2].replaceAll('min', '').trim()) ?? 0;
        final extraMinutes = (h * 60 + m) * sign;

        if (extraMinutes == 0) continue;

        await Supabase.instance.client.from('bank_hours_movements').insert({
          'employee_id': employeeId,
          'movement_date': dateKey,
          'type': extraMinutes > 0 ? 'credit' : 'debit',
          'minutes': extraMinutes.abs(),
          'description': 'Horas extras sincronizadas do ponto - $dateKey',
          'user_id': Supabase.instance.client.auth.currentUser?.id,
        });

        totalSynced += extraMinutes;
        print('✅ [SYNC] Dia $dateKey sincronizado: $extraMinutes minutos');
      }

      await _updateBankHoursBalance(employeeId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sincronização concluída! $totalSynced minutos processados.'), backgroundColor: Colors.green),
      );

      await _loadEmployeeData();
    } catch (e) {
      print('❌ [SYNC] Erro na sincronização: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na sincronização: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _updateBankHoursBalance(int employeeId) async {
    final now = DateTime.now();
    final currentMonthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final resMov = await Supabase.instance.client
        .from('bank_hours_movements')
        .select('minutes, type')
        .eq('employee_id', employeeId);

    int monthBalance = 0;
    for (var m in resMov) {
      final minutes = m['minutes'] as int;
      final type = m['type'] as String;

      if (type == 'credit' || type == 'abono') {
        monthBalance += minutes;
      } else {
        monthBalance -= minutes;
      }
    }

    await Supabase.instance.client
        .from('bank_hours')
        .upsert({
      'employee_id': employeeId,
      'month_year': currentMonthYear,
      'balance': monthBalance,
      'branch_id': widget.employee.branchId,
    }, onConflict: 'employee_id,month_year');

    print('✅ [BALANCE] Saldo do mês $currentMonthYear atualizado para $monthBalance minutos');
  }

  String _calculateExtraHours(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return '0 min';

    final sample = records.first;
    final dataDoDia = DateTime.parse(sample['timestamp']).toLocal();
    final weekday = dataDoDia.weekday;

    if (weekday == 6 || weekday == 7) return '0 min';

    final workedStr = _calculateWorkedHours(records);
    if (workedStr == '--:--') return '0 min';

    final parts = workedStr.split(' ');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[2].replaceAll('min', '').trim()) ?? 0;
    final totalMin = h * 60 + m;

    int expectedMinutes = (weekday == 5) ? 480 : 540;

    int extraMin = totalMin - expectedMinutes;
    if (extraMin.abs() <= 10) return '0 min';

    final eh = extraMin.abs() ~/ 60;
    final em = extraMin.abs() % 60;

    return extraMin > 0
        ? '$eh h ${em.toString().padLeft(2, '0')}'
        : '-$eh h ${em.toString().padLeft(2, '0')}';
  }

  String _calculateWorkedHours(List<Map<String, dynamic>> records) {
    DateTime? entrada, saidaAlmoco, retornoAlmoco, saida;
    for (var r in records) {
      final dt = DateTime.parse(r['timestamp']).toLocal();
      switch (r['entry_type']) {
        case 'entrada': entrada = dt; break;
        case 'saida_almoco': saidaAlmoco = dt; break;
        case 'retorno_almoco': retornoAlmoco = dt; break;
        case 'saida': saida = dt; break;
      }
    }
    if (entrada == null || saida == null) return '--:--';
    var total = saida.difference(entrada);
    if (saidaAlmoco != null && retornoAlmoco != null) total -= retornoAlmoco.difference(saidaAlmoco);
    final h = total.inHours;
    final m = total.inMinutes % 60;
    return '$h h ${m.toString().padLeft(2, '0')}';
  }

  // ==================== SENHA PARA NOVO LANÇAMENTO ====================
  Future<void> _requestPasswordForNewMovement() async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmação de Segurança'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite a senha para criar um novo lançamento:'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (passwordController.text == _adminPassword) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Senha incorreta'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showAddMovementDialog(widget.employee);
    }
  }

  void _showAddMovementDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (ctx) => _AddMovementDialog(
        employee: employee,
        onSaved: () async {
          Navigator.pop(ctx);
          await _loadEmployeeData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lançamento salvo com sucesso!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  // ==================== EXCLUSÃO COM SENHA ====================
  Future<void> _confirmDeleteManualMovement(dynamic movementId, String description) async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Lançamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Deseja excluir:\n"$description"?', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Digite a senha'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (passwordController.text == _adminPassword) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Senha incorreta'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('bank_hours_movements')
            .delete()
            .eq('id', movementId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lançamento excluído com sucesso!'), backgroundColor: Colors.green),
        );

        await _loadEmployeeData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ==================== DIÁLOGO DE NOVO LANÇAMENTO ====================
class _AddMovementDialog extends StatefulWidget {
  final Employee employee;
  final VoidCallback onSaved;

  const _AddMovementDialog({required this.employee, required this.onSaved, super.key});

  @override
  State<_AddMovementDialog> createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<_AddMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'credit';
  DateTime _selectedDate = DateTime.now();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Lançamento no Banco de Horas'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'credit', label: Text('Crédito (+)', style: TextStyle(color: Colors.green))),
                  ButtonSegment(value: 'debit', label: Text('Débito (-)', style: TextStyle(color: Colors.red))),
                ],
                selected: {_type},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _type = newSelection.first);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Data'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Horas'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Informe as horas' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minutos (0-59)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Informe os minutos';
                        final min = int.tryParse(value);
                        if (min == null || min < 0 || min > 59) return '0-59';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo / Descrição *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe o motivo' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _saveMovement, child: const Text('Salvar Lançamento')),
      ],
    );
  }

  Future<void> _saveMovement() async {
    if (!_formKey.currentState!.validate()) return;

    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final totalMinutes = hours * 60 + minutes;

    if (totalMinutes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe pelo menos 1 minuto'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final employeeId = widget.employee.id!;
      final movementDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      await Supabase.instance.client.from('bank_hours_movements').insert({
        'employee_id': employeeId,
        'movement_date': movementDate,
        'type': _type,
        'minutes': totalMinutes,
        'description': _descriptionController.text.trim(),
        'user_id': Supabase.instance.client.auth.currentUser?.id,
      });

      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}