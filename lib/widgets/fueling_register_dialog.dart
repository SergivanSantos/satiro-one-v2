// lib/widgets/fueling_register_dialog.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';
import '../models/vehicle.dart';
import '../providers/employee_provider.dart';
import '../providers/vehicle_provider.dart';

class FuelingRegisterDialog extends StatefulWidget {
  final Vehicle? preSelectedVehicle;
  final bool isAdminMode;

  const FuelingRegisterDialog({
    super.key,
    this.preSelectedVehicle,
    this.isAdminMode = false,
  });

  @override
  State<FuelingRegisterDialog> createState() => _FuelingRegisterDialogState();
}

class _FuelingRegisterDialogState extends State<FuelingRegisterDialog> {
  Vehicle? _selectedVehicle;
  Employee? _selectedEmployee;
  bool _usarConvenio = true;
  bool _isSaving = false;

  final _amountController = TextEditingController();
  final _kmController = TextEditingController();
  final _cardController = TextEditingController();
  XFile? _receiptImage;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.preSelectedVehicle;

    if (!widget.isAdminMode) {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      _selectedEmployee = employeeProvider.currentEmployee;
    }
  }

  // Formata o valor SOMENTE quando o usuário sai do campo
  void _formatAmountOnBlur() {
    final text = _amountController.text.replaceAll(RegExp(r'[^0-9,]'), '');
    if (text.isEmpty) return;

    final value = double.tryParse(text.replaceAll(',', '.')) ?? 0.0;
    final formatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(value);

    _amountController.text = formatted;
  }

  Future<void> _pickImage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Tirar Foto'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Escolher da Galeria'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    final source = result == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);

    if (picked != null && mounted) {
      setState(() => _receiptImage = picked);
    }
  }

  Future<double> _getConvenioSaldoAtual(String branchId) async {
    final mesAnoAtual = DateFormat('yyyy-MM').format(DateTime.now());

    final response = await Supabase.instance.client
        .from('fuel_convenio_saldo')
        .select('saldo_atual')
        .eq('branch_id', branchId)
        .eq('mes_ano', mesAnoAtual)
        .maybeSingle();

    if (response != null) {
      return (response['saldo_atual'] as num?)?.toDouble() ?? 0.0;
    }

    final mesAnterior = DateTime.now().subtract(const Duration(days: 30));
    final mesAnoAnterior = DateFormat('yyyy-MM').format(mesAnterior);

    final anterior = await Supabase.instance.client
        .from('fuel_convenio_saldo')
        .select('saldo_atual')
        .eq('branch_id', branchId)
        .eq('mes_ano', mesAnoAnterior)
        .maybeSingle();

    final saldoAnterior = (anterior?['saldo_atual'] as num?)?.toDouble() ?? 500.0;

    await Supabase.instance.client.from('fuel_convenio_saldo').insert({
      'branch_id': branchId,
      'mes_ano': mesAnoAtual,
      'saldo_atual': saldoAnterior,
    });

    return saldoAnterior;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    final vehicles = vehicleProvider.vehicles;
    final employees = employeeProvider.employees;

    return AlertDialog(
      title: const Text('Registrar Abastecimento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Vehicle>(
              value: _selectedVehicle,
              decoration: const InputDecoration(labelText: 'Veículo *'),
              isExpanded: true,
              items: vehicles.isEmpty
                  ? [const DropdownMenuItem(value: null, child: Text('Carregando veículos...'))]
                  : vehicles.map((v) => DropdownMenuItem(
                value: v,
                child: Text('${v.placa ?? '—'} - ${v.modelo ?? 'Sem modelo'}'),
              )).toList(),
              onChanged: (v) => setState(() => _selectedVehicle = v),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Forma de Pagamento', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Convênio'),
                            value: true,
                            groupValue: _usarConvenio,
                            onChanged: (value) => setState(() => _usarConvenio = value!),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Cartão'),
                            value: false,
                            groupValue: _usarConvenio,
                            onChanged: (value) => setState(() => _usarConvenio = value!),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (widget.isAdminMode) ...[
              DropdownButtonFormField<Employee>(
                value: _selectedEmployee,
                decoration: const InputDecoration(labelText: 'Funcionário'),
                items: employees.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.name ?? 'Funcionário ${e.id}'),
                )).toList(),
                onChanged: (e) => setState(() => _selectedEmployee = e),
                isExpanded: true,
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
              ),
              onEditingComplete: _formatAmountOnBlur,   // ← Formata só quando sair do campo
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _kmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hodômetro atual (km)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _cardController,
              decoration: const InputDecoration(
                labelText: 'Cartão (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Anexar comprovante'),
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            if (_receiptImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Foto selecionada: ${_receiptImage!.name}',
                  style: const TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _isSaving ? null : _registrarAbastecimento,
          child: _isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          )
              : const Text('Registrar', style: TextStyle(color: Colors.orange)),
        ),
      ],
    );
  }

  Future<void> _registrarAbastecimento() async {
    if (_selectedVehicle == null || _amountController.text.isEmpty || _kmController.text.isEmpty || _receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    final clean = _amountController.text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    final amount = double.tryParse(clean) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor inválido'), backgroundColor: Colors.orange),
      );
      setState(() => _isSaving = false);
      return;
    }

    int? employeeIdToUse = widget.isAdminMode ? _selectedEmployee?.id : Provider.of<EmployeeProvider>(context, listen: false).currentEmployee?.id;

    final km = int.tryParse(_kmController.text) ?? 0;
    final cardNumber = _cardController.text.trim();

    try {
      final bytes = await _receiptImage!.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_receiptImage!.name}';
      final storagePath = 'receipts/$fileName';

      await Supabase.instance.client.storage.from('receipts').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final receiptUrl = Supabase.instance.client.storage.from('receipts').getPublicUrl(storagePath);

      if (_usarConvenio) {
        final branchId = _selectedVehicle!.branchId;
        if (branchId == null) throw 'Filial do veículo não informada';

        final saldoAtual = await _getConvenioSaldoAtual(branchId);

        if (saldoAtual < amount) {
          throw 'Saldo do convênio da filial insuficiente (restante: R\$ ${saldoAtual.toStringAsFixed(2)})';
        }

        final mesAno = DateFormat('yyyy-MM').format(DateTime.now());

        await Supabase.instance.client
            .from('fuel_convenio_saldo')
            .update({'saldo_atual': saldoAtual - amount})
            .eq('branch_id', branchId)
            .eq('mes_ano', mesAno);
      }

      await Supabase.instance.client.from('vehicle_fuel_logs').insert({
        'vehicle_id': _selectedVehicle!.id,
        'technician_id': employeeIdToUse,
        'amount': amount,
        'odometer': km,
        'card_number': cardNumber.isEmpty ? null : cardNumber,
        'receipt_url': receiptUrl,
        'pagamento': _usarConvenio ? 'convenio' : 'cartao',
      });

      if (employeeIdToUse != null && km > (_selectedVehicle!.odometroInicial ?? 0)) {
        await Provider.of<VehicleProvider>(context, listen: false).assignVehicleToTechnician(
          context: context,
          vehicleId: _selectedVehicle!.id!,
          technicianId: employeeIdToUse,
          odometro: km,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abastecimento registrado com sucesso!'), backgroundColor: Colors.green),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao registrar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _kmController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}