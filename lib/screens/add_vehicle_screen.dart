// lib/screens/admin/add_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/branch_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;
  const AddVehicleScreen({super.key, this.vehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _placaCtrl;
  late TextEditingController _modeloCtrl;
  late TextEditingController _anoCtrl;
  late TextEditingController _corCtrl;
  late TextEditingController _odometroCtrl;
  late TextEditingController _capacidadeCtrl;
  late TextEditingController _observacoesCtrl;
  late TextEditingController _kmContratadoCtrl;
  late TextEditingController _kmInicialMesCtrl;
  late TextEditingController _mesAnoReferenciaCtrl;

  String _status = 'disponivel';
  String? _branchId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _placaCtrl = TextEditingController(text: widget.vehicle?.placa ?? '');
    _modeloCtrl = TextEditingController(text: widget.vehicle?.modelo ?? '');
    _anoCtrl = TextEditingController(text: widget.vehicle?.ano?.toString() ?? '');
    _corCtrl = TextEditingController(text: widget.vehicle?.cor ?? '');
    _odometroCtrl = TextEditingController(text: widget.vehicle?.odometroInicial?.toString() ?? '');
    _capacidadeCtrl = TextEditingController(text: widget.vehicle?.capacidade?.toString() ?? '');
    _observacoesCtrl = TextEditingController(text: widget.vehicle?.observacoes ?? '');
    _kmContratadoCtrl = TextEditingController(text: widget.vehicle?.kmContratadoMensal?.toString() ?? '');
    _kmInicialMesCtrl = TextEditingController(text: widget.vehicle?.kmInicialMesAtual?.toString() ?? '');
    _mesAnoReferenciaCtrl = TextEditingController(text: widget.vehicle?.mesAnoReferencia ?? '');

    _status = widget.vehicle?.status ?? 'disponivel';
    _branchId = widget.vehicle?.branchId;

    // Pré-seleciona filial do usuário (se não for super)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserBranch();
    });
  }

  void _loadUserBranch() {
    final employee = Provider.of<EmployeeProvider>(context, listen: false).currentEmployee;
    final isSuper = employee?.role?.contains('super_') == true || employee?.role == 'admin';

    if (!isSuper && employee?.branchId != null && _branchId == null) {
      setState(() => _branchId = employee!.branchId);
    }
  }

  @override
  void dispose() {
    _placaCtrl.dispose();
    _modeloCtrl.dispose();
    _anoCtrl.dispose();
    _corCtrl.dispose();
    _odometroCtrl.dispose();
    _capacidadeCtrl.dispose();
    _observacoesCtrl.dispose();
    _kmContratadoCtrl.dispose();
    _kmInicialMesCtrl.dispose();
    _mesAnoReferenciaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchProvider = Provider.of<BranchProvider>(context);
    final employee = Provider.of<EmployeeProvider>(context).currentEmployee;
    final isSuperUser = employee?.role?.contains('super_') == true || employee?.role == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Text(widget.vehicle == null ? 'Novo Veículo' : 'Editar Veículo'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Informações Básicas
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _placaCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(labelText: 'Placa *', border: OutlineInputBorder()),
                            validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _modeloCtrl,
                            decoration: const InputDecoration(labelText: 'Modelo *', border: OutlineInputBorder()),
                            validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _anoCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Ano', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _corCtrl,
                                  decoration: const InputDecoration(labelText: 'Cor', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Odômetro + Capacidade
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _odometroCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Odômetro Inicial *', border: OutlineInputBorder()),
                            validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _capacidadeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Capacidade (Pessoas)', border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Franquia KM
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Franquia de KM Mensal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _kmContratadoCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'KM Contratado Mensal', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _kmInicialMesCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'KM Inicial Mês Atual', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _mesAnoReferenciaCtrl,
                            decoration: const InputDecoration(labelText: 'Mês/Ano Referência (ex: 2026-03)', border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Status + Observações
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(labelText: 'Status *', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'disponivel', child: Text('Disponível')),
                              DropdownMenuItem(value: 'em_uso', child: Text('Em uso')),
                              DropdownMenuItem(value: 'manutencao', child: Text('Manutenção')),
                            ],
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _observacoesCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // FILIAL
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<String>(
                        value: _branchId,
                        decoration: const InputDecoration(
                          labelText: 'Filial *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: branchProvider.branches.map((b) {
                          return DropdownMenuItem(value: b.id, child: Text(b.name ?? b.id));
                        }).toList(),
                        onChanged: isSuperUser
                            ? (value) => setState(() => _branchId = value)
                            : null,
                        validator: (v) => v == null ? 'Selecione a filial' : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botão Salvar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'SALVANDO...' : 'SALVAR VEÍCULO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final vehicle = Vehicle(
      id: widget.vehicle?.id,
      placa: _placaCtrl.text.trim().toUpperCase(),
      modelo: _modeloCtrl.text.trim(),
      ano: int.tryParse(_anoCtrl.text),
      cor: _corCtrl.text.trim(),
      odometroInicial: int.tryParse(_odometroCtrl.text) ?? 0,
      capacidade: int.tryParse(_capacidadeCtrl.text),
      observacoes: _observacoesCtrl.text.trim().isEmpty ? null : _observacoesCtrl.text.trim(),
      status: _status,
      branchId: _branchId,
      kmContratadoMensal: int.tryParse(_kmContratadoCtrl.text),
      kmInicialMesAtual: int.tryParse(_kmInicialMesCtrl.text),
      mesAnoReferencia: _mesAnoReferenciaCtrl.text.trim().isEmpty ? null : _mesAnoReferenciaCtrl.text.trim(),
    );

    try {
      final provider = Provider.of<VehicleProvider>(context, listen: false);

      if (widget.vehicle == null) {
        await provider.addVehicle(context, vehicle);
      } else {
        await provider.updateVehicle(context, vehicle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veículo salvo com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}