import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import '../../providers/branch_provider.dart';

class PontoRhScreen extends StatefulWidget {
  const PontoRhScreen({super.key});

  @override
  State<PontoRhScreen> createState() => _PontoRhScreenState();
}

class _PontoRhScreenState extends State<PontoRhScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  DateTime? _startDate;
  DateTime? _endDate;
  Employee? _selectedEmployee;
  String? _selectedBranchId;

  List<Map<String, dynamic>> _registros = [];
  List<Employee> _funcionariosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final currentEmployee = employeeProvider.currentEmployee;

      if (currentEmployee == null) throw Exception('Nenhum funcionário logado');

      final isSuperRh = currentEmployee.role == 'super_rh';
      final branchId = currentEmployee.branchId;

      List<Employee> funcionarios = isSuperRh
          ? employeeProvider.employees
          : employeeProvider.employees.where((e) => e.branchId == branchId).toList();

      setState(() => _funcionariosFiltrados = funcionarios);

      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;

      await _carregarRegistrosPeriodo();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados: $e';
      });
    }
  }

  Future<void> _carregarRegistrosPeriodo() async {
    if (_startDate == null || _endDate == null) return;

    final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);

    try {
      final response = await Supabase.instance.client
          .from('time_entries')
          .select('''
            id, employee_id, entry_type, timestamp, latitude, longitude, accuracy,
            observations, document_url,
            employees!time_entries_employee_id_fkey(name, branch_id, branch:branches!employees_branch_id_fkey(name))
          ''')
          .gte('timestamp', '$startStr 00:00:00+00')
          .lte('timestamp', '$endStr 23:59:59+00')
          .order('timestamp', ascending: true);

      final filteredResponse = response.where((r) {
        final employeeData = r['employees'] as Map<String, dynamic>? ?? {};
        final branchId = employeeData['branch_id'] as String?;

        if (_selectedBranchId != null && branchId != _selectedBranchId) return false;
        if (_selectedEmployee != null && r['employee_id'] != _selectedEmployee!.id) return false;
        return true;
      }).map((r) {
        DateTime? localTime;
        try {
          final ts = r['timestamp'] as String?;
          if (ts != null) localTime = DateTime.parse(ts).toLocal();
        } catch (_) {}
        return {...r, 'timestamp_local': localTime};
      }).toList();

      setState(() => _registros = filteredResponse);
    } catch (e) {
      print('[FILTRO_DATA] ERRO: $e');
      setState(() => _errorMessage = 'Erro ao carregar: $e');
    }
  }

  // ==================== BOTÕES RÁPIDOS ====================
  void _setPeriodoMesAtual() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
    });
    _carregarRegistrosPeriodo();
  }

  void _setPeriodoMesAnterior() {
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 1);
    setState(() {
      _startDate = previousMonth;
      _endDate = DateTime(now.year, now.month, 0);
    });
    _carregarRegistrosPeriodo();
  }

  void _setPeriodoUltimos30Dias() {
    final now = DateTime.now();
    setState(() {
      _startDate = now.subtract(const Duration(days: 30));
      _endDate = now;
    });
    _carregarRegistrosPeriodo();
  }

  void _showFilterDialog() {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final branchProvider = Provider.of<BranchProvider>(context, listen: false);
    final isSuperRh = employeeProvider.currentEmployee?.role == 'super_rh';

    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;
    Employee? tempEmployee = _selectedEmployee;
    String? tempBranch = _selectedBranchId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Filtros de Ponto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Data inicial'),
                  subtitle: Text(tempStart != null ? DateFormat('dd/MM/yyyy').format(tempStart!) : 'Selecionar'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: tempStart ?? DateTime.now(),
                      firstDate: DateTime(2010),
                      lastDate: DateTime(2030),
                      locale: const Locale('pt', 'BR'),
                    );
                    if (picked != null) setDialogState(() => tempStart = picked);
                  },
                ),
                ListTile(
                  title: const Text('Data final'),
                  subtitle: Text(tempEnd != null ? DateFormat('dd/MM/yyyy').format(tempEnd!) : 'Selecionar'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: tempEnd ?? DateTime.now(),
                      firstDate: DateTime(2010),
                      lastDate: DateTime(2030),
                      locale: const Locale('pt', 'BR'),
                    );
                    if (picked != null) setDialogState(() => tempEnd = picked);
                  },
                ),
                const Divider(),
                if (isSuperRh)
                  DropdownButtonFormField<String?>(
                    value: tempBranch,
                    decoration: const InputDecoration(labelText: 'Filial'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas as filiais')),
                      ...branchProvider.branches.map(
                            (b) => DropdownMenuItem(value: b.id, child: Text(b.name ?? b.id)),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => tempBranch = v),
                  ),
                DropdownButtonFormField<Employee?>(
                  value: tempEmployee,
                  decoration: const InputDecoration(labelText: 'Funcionário'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos os funcionários')),
                    ..._funcionariosFiltrados.map(
                          (e) => DropdownMenuItem(value: e, child: Text(e.name ?? e.id.toString())),
                    ),
                  ],
                  onChanged: (e) => setDialogState(() => tempEmployee = e),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = tempStart;
                  _endDate = tempEnd;
                  _selectedEmployee = tempEmployee;
                  _selectedBranchId = tempBranch;
                });
                _carregarRegistrosPeriodo();
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoramento de Ponto'),
        actions: [
          IconButton(icon: const Icon(Icons.today), tooltip: 'Mês Atual', onPressed: _setPeriodoMesAtual),
          IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Mês Anterior', onPressed: _setPeriodoMesAnterior),
          IconButton(icon: const Icon(Icons.history), tooltip: 'Últimos 30 dias', onPressed: _setPeriodoUltimos30Dias),
          IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Gerar Relatório PDF', onPressed: _gerarRelatorioPDF),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarRegistrosPeriodo),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _registros.isEmpty
          ? const Center(child: Text('Nenhum registro encontrado no período'))
          : Consumer<EmployeeProvider>(
        builder: (context, employeeProvider, _) {
          _funcionariosFiltrados = employeeProvider.employees;
          return _buildEmployeeDayTable();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _carregarRegistrosPeriodo,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // ==================== TABELA PRINCIPAL ====================
  Widget _buildEmployeeDayTable() {
    final Map<int, Map<String, List<Map<String, dynamic>>>> grouped = {};

    for (var r in _registros) {
      final empId = r['employee_id'] as int? ?? 0;
      final ts = r['timestamp_local'] as DateTime?;
      if (ts == null) continue;
      final dateKey = DateFormat('yyyy-MM-dd').format(ts);

      grouped.putIfAbsent(empId, () => {});
      grouped[empId]!.putIfAbsent(dateKey, () => []);
      grouped[empId]![dateKey]!.add(r);
    }

    final employeeIds = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: employeeIds.length,
      itemBuilder: (context, index) {
        final empId = employeeIds[index];
        final daysMap = grouped[empId]!;

        final allDays = <String, List<Map<String, dynamic>>>{};
        DateTime current = _startDate!;
        while (!current.isAfter(_endDate!)) {
          final weekday = current.weekday;
          if (weekday >= 1 && weekday <= 5) {
            final dateKey = DateFormat('yyyy-MM-dd').format(current);
            allDays[dateKey] = daysMap[dateKey] ?? [];
          }
          current = current.add(const Duration(days: 1));
        }

        int totalDays = allDays.length;
        int incompleteDays = 0;
        int faltas = 0;
        int diasSemRefeicao = 0;
        Duration totalWorked = Duration.zero;
        int extraPositivaMin = 0;
        int extraNegativaMin = 0;

        for (var records in allDays.values) {
          final types = records.map((r) => r['entry_type'] as String?).toSet();

          final hasAll = types.contains('entrada') &&
              types.contains('saida_almoco') &&
              types.contains('retorno_almoco') &&
              types.contains('saida');

          if (!hasAll) incompleteDays++;

          final obs = records.isNotEmpty ? (records.first['observations'] ?? '') : 'Falta';
          final obsLower = obs.toLowerCase();
          final isFeriado = obsLower.contains('feriado');
          final isFalta = records.isEmpty || obsLower.contains('falta');

          if (isFalta && !isFeriado) {
            faltas++;
            diasSemRefeicao++;
          }

          final hasMealBreak = types.contains('saida_almoco') && types.contains('retorno_almoco');
          if (!hasMealBreak && records.isNotEmpty && !isFeriado && !isFalta) {
            diasSemRefeicao++;
          }

          final workedStr = _calculateWorkedHours(records);
          if (workedStr != '--:--') {
            final parts = workedStr.split(' ');
            final h = int.tryParse(parts[0]) ?? 0;
            final m = int.tryParse(parts[2].replaceAll('min', '').trim()) ?? 0;
            totalWorked += Duration(hours: h, minutes: m);
          }

          final extraStr = _calculateExtraHours(records);
          if (extraStr != '0 min') {
            final parts = extraStr.split(' ');
            final sign = extraStr.startsWith('-') ? -1 : 1;
            final eh = int.tryParse(parts[0].replaceAll('-', '')) ?? 0;
            final em = int.tryParse(parts[2].replaceAll('min', '').trim()) ?? 0;
            if (sign > 0) extraPositivaMin += eh * 60 + em;
            else extraNegativaMin += eh * 60 + em;
          }
        }

        final saldoLiquidoMin = extraPositivaMin - extraNegativaMin;

        final employee = _funcionariosFiltrados.firstWhere(
              (e) => e.id == empId,
          orElse: () => Employee(id: empId, name: 'Funcionário $empId'),
        );
        final nome = employee.name ?? 'Funcionário $empId';

        final subtitleText = '$totalDays dias • $incompleteDays incompletos • $faltas faltas';

        final sortedDays = allDays.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            initiallyExpanded: false,
            leading: const Icon(Icons.person, color: Colors.teal),
            title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
            subtitle: Text(subtitleText, style: TextStyle(fontSize: 13, color: incompleteDays > 0 ? Colors.orange[800] : Colors.grey[700])),

            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _headerCell('Data', Icons.calendar_today)),
                    Expanded(child: _headerCell('Entrada', Icons.login)),
                    Expanded(child: _headerCell('Saída Almoço', Icons.lunch_dining)),
                    Expanded(child: _headerCell('Retorno', Icons.keyboard_return)),
                    Expanded(child: _headerCell('Saída', Icons.logout)),
                    Expanded(child: _headerCell('Trab.', Icons.timer)),
                    Expanded(child: _headerCell('Extras', Icons.add_circle_outline)),
                    Expanded(child: _headerCell('Status', Icons.info)),
                    Expanded(child: _headerCell('Observações', Icons.note)),
                    Expanded(child: _headerCell('Comprovante', Icons.attach_file)),
                    Expanded(flex: 2, child: _headerCell('Ações', Icons.settings)),
                  ],
                ),
              ),
              ...sortedDays.map((entry) {
                final dateKey = entry.key;
                final records = entry.value;

                final dataFormatada = DateFormat('dd/MM (EEE)', 'pt_BR').format(DateTime.parse(dateKey));

                final entrada = records.firstWhere((r) => r['entry_type'] == 'entrada', orElse: () => <String, dynamic>{});
                final saidaAlmoco = records.firstWhere((r) => r['entry_type'] == 'saida_almoco', orElse: () => <String, dynamic>{});
                final retornoAlmoco = records.firstWhere((r) => r['entry_type'] == 'retorno_almoco', orElse: () => <String, dynamic>{});
                final saida = records.firstWhere((r) => r['entry_type'] == 'saida', orElse: () => <String, dynamic>{});

                final horasTrab = _calculateWorkedHours(records);
                final horasExtra = _calculateExtraHours(records);
                final status = _getDayStatus(records);

                final obs = records.isNotEmpty ? (records.first['observations'] ?? '') : 'Falta';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(dataFormatada, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                      Expanded(child: _compactTime(entrada, obs)),
                      Expanded(child: _compactTime(saidaAlmoco, obs)),
                      Expanded(child: _compactTime(retornoAlmoco, obs)),
                      Expanded(child: _compactTime(saida, obs)),
                      Expanded(child: Text(horasTrab, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                      Expanded(child: Text(horasExtra, style: TextStyle(fontSize: 13, color: horasExtra.contains('-') ? Colors.red : Colors.orange[800]), textAlign: TextAlign.center)),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: status['color'].withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: Text(status['text'], style: TextStyle(fontSize: 11, color: status['color']), textAlign: TextAlign.center),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editObservation(records, dateKey, empId),
                          child: Text(obs, style: const TextStyle(fontSize: 13, color: Colors.blue), textAlign: TextAlign.center),
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          icon: const Icon(Icons.attach_file, size: 18, color: Colors.blue),
                          onPressed: () => _attachDocument(records),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _showEditPointDialog(records)),
                            IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _confirmDeleteRecord(records)),
                            IconButton(icon: const Icon(Icons.location_on, size: 18, color: Colors.blue), onPressed: () => _showLocationSelectionDialog(records)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              if (_selectedEmployee != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  padding: const EdgeInsets.all(14),
                  width: MediaQuery.of(context).size.width * 0.30,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Funcionário: ${nome}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                      Text(
                        'Período: ${DateFormat('dd/MM/yyyy').format(_startDate!)} a ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                        style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                      ),
                      const Divider(height: 16, thickness: 1),
                      _resumoItem('Quantos dias', '$totalDays'),
                      _resumoItem('Horas trabalhadas', '${totalWorked.inHours}h ${(totalWorked.inMinutes % 60).toString().padLeft(2, '0')}'),
                      _resumoItem('Horas Extras Positivas', extraPositivaMin > 0 ? '+${extraPositivaMin ~/ 60}h ${(extraPositivaMin % 60).toString().padLeft(2, '0')}' : '0 min'),
                      _resumoItem('Horas Negativas', extraNegativaMin > 0 ? '-${extraNegativaMin ~/ 60}h ${(extraNegativaMin % 60).toString().padLeft(2, '0')}' : '0 min'),
                      _resumoItem('Quantidade de Faltas', '$faltas'),
                      _resumoItem('Dias sem refeição', '$diasSemRefeicao'),
                      _resumoItem('Saldo Líquido', saldoLiquidoMin >= 0
                          ? '+${saldoLiquidoMin ~/ 60}h ${(saldoLiquidoMin % 60).toString().padLeft(2, '0')}'
                          : '-${(saldoLiquidoMin.abs() ~/ 60)}h ${(saldoLiquidoMin.abs() % 60).toString().padLeft(2, '0')}'),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Adicionar Dia Manualmente'),
                  onPressed: () => _addNewDayForEmployee(empId),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.teal), foregroundColor: Colors.teal),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _resumoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _calculateWorkedHours(List<Map<String, dynamic>> records) {
    DateTime? entrada, saidaAlmoco, retornoAlmoco, saida;
    for (var r in records) {
      final dt = r['timestamp_local'] as DateTime?;
      if (dt == null) continue;
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

  String _calculateExtraHours(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return '0 min';

    final sample = records.first;
    final dataDoDia = (sample['timestamp_local'] as DateTime?) ?? DateTime.now();
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

  Future<void> _editObservation(List<Map<String, dynamic>> recordsOfDay, String dateKey, int empId) async {
    String currentObs = recordsOfDay.isNotEmpty ? (recordsOfDay.first['observations'] ?? '') : 'Falta';

    final controller = TextEditingController(text: currentObs);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Observação'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Observação'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    if (recordsOfDay.isEmpty) {
      final newDateTimeLocal = DateTime.parse(dateKey).add(const Duration(hours: 8));
      final newDateTimeUtc = newDateTimeLocal.toUtc();

      await Supabase.instance.client.from('time_entries').insert({
        'employee_id': empId,
        'entry_type': 'entrada',
        'timestamp': newDateTimeUtc.toIso8601String(),
        'observations': result,
      });
    } else {
      await Supabase.instance.client
          .from('time_entries')
          .update({'observations': result})
          .eq('id', recordsOfDay.first['id']);
    }

    await _carregarRegistrosPeriodo();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Observação salva!'), backgroundColor: Colors.green));
  }

  Future<void> _attachDocument(List<Map<String, dynamic>> recordsOfDay) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
    final storagePath = 'documents/$fileName';

    try {
      await Supabase.instance.client.storage.from('documents').uploadBinary(storagePath, bytes);
      final url = Supabase.instance.client.storage.from('documents').getPublicUrl(storagePath);

      await Supabase.instance.client
          .from('time_entries')
          .update({'document_url': url})
          .eq('id', recordsOfDay.first['id']);

      await _carregarRegistrosPeriodo();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento anexado com sucesso!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao anexar documento: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ==================== MÉTODOS QUE ESTAVAM FALTANDO ====================
  void _showEditPointDialog(List<Map<String, dynamic>> recordsOfDay) {
    print('[EDIT_PONTO] Iniciando edição de dia existente - Registros: ${recordsOfDay.length}');
    final empId = recordsOfDay.isNotEmpty ? (recordsOfDay.first['employee_id'] as int? ?? 0) : 0;
    _showEditPointDialogInternal(recordsOfDay, null, empId);
  }

  void _showEditPointDialogForNewDay(int empId, DateTime forcedDate) {
    print('[EDIT_PONTO] Iniciando adição de dia NOVO - Emp ID: $empId | Data: ${DateFormat('dd/MM/yyyy').format(forcedDate)}');
    _showEditPointDialogInternal([], forcedDate, empId);
  }

  void _showEditPointDialogInternal(List<Map<String, dynamic>> recordsOfDay, DateTime? forcedDate, int empId) {
    print('[EDIT_PONTO_INTERNAL] Entrando no diálogo interno | Emp ID recebido: $empId');

    final sample = recordsOfDay.isNotEmpty ? recordsOfDay.first : null;

    final baseDate = forcedDate ?? (sample != null ? (sample['timestamp_local'] as DateTime) : DateTime.now());
    final dateKey = DateFormat('yyyy-MM-dd').format(baseDate);

    print('[EDIT_PONTO_INTERNAL] Data base: $dateKey (forçada? ${forcedDate != null})');

    String selectedType = 'entrada';
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: forcedDate == null ? const Text('Editar Ponto') : const Text('Adicionar Ponto - Dia Novo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                items: const [
                  DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                  DropdownMenuItem(value: 'saida_almoco', child: Text('Saída Almoço')),
                  DropdownMenuItem(value: 'retorno_almoco', child: Text('Retorno Almoço')),
                  DropdownMenuItem(value: 'saida', child: Text('Saída')),
                ],
                onChanged: (v) => setDialogState(() => selectedType = v!),
                decoration: const InputDecoration(labelText: 'Tipo de ponto'),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Horário'),
                trailing: Text(selectedTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (picked != null) setDialogState(() => selectedTime = picked);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Motivo (obrigatório)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o motivo')));
                  print('[EDIT_PONTO_INTERNAL] Falha: motivo vazio');
                  return;
                }

                final newDateTimeLocal = DateTime(
                  baseDate.year,
                  baseDate.month,
                  baseDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final newDateTimeUtc = newDateTimeLocal.toUtc();

                print('[EDIT_PONTO_INTERNAL] Data base: $dateKey');
                print('[EDIT_PONTO_INTERNAL] Novo horário local: ${newDateTimeLocal.toString()}');
                print('[EDIT_PONTO_INTERNAL] Novo timestamp UTC enviado: ${newDateTimeUtc.toIso8601String()}');

                try {
                  final employeeId = Provider.of<EmployeeProvider>(context, listen: false).currentEmployee!.id;
                  print('[EDIT_PONTO_INTERNAL] ID do usuário logado: $employeeId');

                  if (recordsOfDay.isNotEmpty && recordsOfDay.firstWhere((r) => r['entry_type'] == selectedType, orElse: () => {}).isNotEmpty) {
                    final existingRecord = recordsOfDay.firstWhere((r) => r['entry_type'] == selectedType);
                    print('[EDIT_PONTO_INTERNAL] Atualizando registro existente (ID: ${existingRecord['id']})');
                    await Supabase.instance.client
                        .from('time_entries')
                        .update({
                      'timestamp': newDateTimeUtc.toIso8601String(),
                      'edited_by': employeeId,
                      'edit_reason': reason,
                      'updated_at': DateTime.now().toUtc().toIso8601String(),
                    })
                        .eq('id', existingRecord['id']);
                  } else {
                    print('[EDIT_PONTO_INTERNAL] Criando novo registro (tipo: $selectedType)');
                    await Supabase.instance.client.from('time_entries').insert({
                      'employee_id': empId,
                      'branch_id': Provider.of<EmployeeProvider>(context, listen: false).currentEmployee?.branchId,
                      'entry_type': selectedType,
                      'timestamp': newDateTimeUtc.toIso8601String(),
                      'latitude': null,
                      'longitude': null,
                      'accuracy': null,
                      'edited_by': employeeId,
                      'edit_reason': reason,
                    });
                  }

                  print('[EDIT_PONTO_INTERNAL] Operação concluída com sucesso');
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ponto salvo com sucesso!'), backgroundColor: Colors.green),
                  );

                  await _carregarRegistrosPeriodo();
                } catch (e, stack) {
                  print('[EDIT_PONTO_INTERNAL] ERRO ao salvar: $e');
                  print('[EDIT_PONTO_INTERNAL] Stacktrace completo: $stack');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  void _openMap(double lat, double lng) async {
    final url = 'https://maps.google.com/?q=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // ==================== OUTROS MÉTODOS ====================
  Widget _headerCell(String title, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 14, color: Colors.grey[700]),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      ],
    );
  }

  Widget _compactTime(Map<String, dynamic> record, String obs) {
    if (obs.toLowerCase().contains('feriado') || obs == 'Falta') {
      return const Text('--:--', style: TextStyle(fontSize: 13));
    }
    final time = record['timestamp_local'] != null
        ? DateFormat('HH:mm').format(record['timestamp_local'] as DateTime)
        : '--:--';
    return Text(time, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center);
  }

  Map<String, dynamic> _getDayStatus(List<Map<String, dynamic>> records) {
    final obs = records.isNotEmpty ? (records.first['observations'] ?? '') : 'Falta';
    final obsLower = obs.toLowerCase();

    if (obsLower.contains('falta') || records.isEmpty) {
      return {'text': 'Falta', 'color': Colors.red};
    }
    if (obsLower.contains('feriado')) {
      return {'text': 'Feriado', 'color': Colors.orange};
    }

    final types = records.map((r) => r['entry_type'] as String?).toSet();
    final hasAll = types.contains('entrada') && types.contains('saida_almoco') && types.contains('retorno_almoco') && types.contains('saida');

    if (hasAll) return {'text': 'Completo', 'color': Colors.green};
    return {'text': 'Incompleto', 'color': Colors.orange};
  }

  Future<void> _confirmDeleteRecord(List<Map<String, dynamic>> recordsOfDay) async {
    final record = recordsOfDay.isNotEmpty ? recordsOfDay.first : null;
    if (record == null) return;

    final entryType = record['entry_type'] as String? ?? 'ponto';
    final time = record['timestamp_local'] != null
        ? DateFormat('dd/MM HH:mm').format(record['timestamp_local'] as DateTime)
        : 'desconhecido';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: Text('Deseja realmente excluir o registro de $entryType às $time?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('time_entries')
          .delete()
          .eq('id', record['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro excluído com sucesso!'), backgroundColor: Colors.green),
      );

      await _carregarRegistrosPeriodo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showLocationSelectionDialog(List<Map<String, dynamic>> records) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escolha o horário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: records.map((r) {
            final tipo = r['entry_type'] as String;
            final time = r['timestamp_local'] != null
                ? DateFormat('HH:mm').format(r['timestamp_local'] as DateTime)
                : '--:--';
            final lat = r['latitude'] as double?;
            final lng = r['longitude'] as double?;

            return ListTile(
              title: Text('$tipo - $time'),
              trailing: const Icon(Icons.location_on, color: Colors.blue),
              onTap: () {
                if (lat != null && lng != null) {
                  Navigator.pop(ctx);
                  _openMap(lat, lng);
                }
              },
            );
          }).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))],
      ),
    );
  }

  Future<void> _addNewDayForEmployee(int empId) async {
    print('[ADD_DAY] Iniciando adição de dia novo para funcionário ID: $empId');

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );

    if (picked == null) {
      print('[ADD_DAY] Usuário cancelou a seleção de data');
      return;
    }

    print('[ADD_DAY] Data selecionada: ${DateFormat('dd/MM/yyyy').format(picked)}');
    _showEditPointDialogForNewDay(empId, picked);
  }

  Future<void> _gerarRelatorioPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relatório PDF em desenvolvimento')));
  }
}