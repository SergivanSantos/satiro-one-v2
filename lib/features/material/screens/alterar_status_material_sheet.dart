// lib/features/material/screens/alterar_status_material_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../obra/models/obra_material.dart';
import '../providers/material_provider.dart';

class AlterarStatusMaterialSheet extends StatefulWidget {
  final ObraMaterial material;
  final VoidCallback onSuccess;

  const AlterarStatusMaterialSheet({
    super.key,
    required this.material,
    required this.onSuccess,
  });

  @override
  State<AlterarStatusMaterialSheet> createState() => _AlterarStatusMaterialSheetState();
}

class _AlterarStatusMaterialSheetState extends State<AlterarStatusMaterialSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _novoStatus;
  final _observacaoController = TextEditingController();
  final _nfController = TextEditingController();
  final _fornecedorController = TextEditingController();
  final _valorUnitarioController = TextEditingController();

  DateTime? _dataCompra;
  DateTime? _dataPrevisao;

  bool _isSaving = false;

  final List<String> _statusDisponiveis = [
    'a_comprar',
    'separado',
    'em_cotacao',
    'comprado',
    'em_transito',
    'entregue',
    'cancelado',
    'devolvido',
  ];

  @override
  void initState() {
    super.initState();
    _novoStatus = widget.material.status;
    _nfController.text = widget.material.numeroNf ?? '';
    _fornecedorController.text = widget.material.fornecedor ?? '';
    if (widget.material.valorUnitario != null) {
      _valorUnitarioController.text = widget.material.valorUnitario!.toStringAsFixed(2);
    }
    _dataCompra = widget.material.dataCompra;
    _dataPrevisao = widget.material.dataPrevisaoEntrega;
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    _nfController.dispose();
    _fornecedorController.dispose();
    _valorUnitarioController.dispose();
    super.dispose();
  }

  bool get _mostrarCamposCompra =>
      ['comprado', 'em_transito', 'entregue'].contains(_novoStatus);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                widget.material.materialNome,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "${widget.material.quantidade} ${widget.material.unidade}",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Status
              DropdownButtonFormField<String>(
                value: _novoStatus,
                decoration: const InputDecoration(
                  labelText: "Novo Status *",
                  border: OutlineInputBorder(),
                ),
                items: _statusDisponiveis.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(ObraMaterial.statusLabels[s] ?? s),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _novoStatus = value);
                },
              ),
              const SizedBox(height: 16),

              // Campos de compra (aparecem dinamicamente)
              if (_mostrarCamposCompra) ...[
                TextFormField(
                  controller: _nfController,
                  decoration: const InputDecoration(
                    labelText: "Número da NF",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fornecedorController,
                  decoration: const InputDecoration(
                    labelText: "Fornecedor",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorUnitarioController,
                  decoration: const InputDecoration(
                    labelText: "Valor Unitário (R\$)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),

                // Datas
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        label: "Data da Compra",
                        value: _dataCompra,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dataCompra ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _dataCompra = date);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateField(
                        label: "Previsão Entrega",
                        value: _dataPrevisao,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dataPrevisao ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _dataPrevisao = date);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Observação
              TextFormField(
                controller: _observacaoController,
                decoration: const InputDecoration(
                  labelText: "Observação",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                      : const Text(
                    "SALVAR ALTERAÇÃO",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        child: Text(
          value != null ? DateFormat('dd/MM/yyyy').format(value) : "Selecionar",
          style: TextStyle(
            color: value != null ? Colors.black87 : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<MaterialProvider>();

    double? valorUnitario;
    if (_valorUnitarioController.text.isNotEmpty) {
      valorUnitario = double.tryParse(_valorUnitarioController.text.replaceAll(',', '.'));
    }

    final sucesso = await provider.atualizarStatusMaterialComHistorico(
      material: widget.material,
      novoStatus: _novoStatus,
      observacao: _observacaoController.text.trim().isEmpty
          ? null
          : _observacaoController.text.trim(),
      numeroNf: _nfController.text.trim().isEmpty ? null : _nfController.text.trim(),
      fornecedor: _fornecedorController.text.trim().isEmpty
          ? null
          : _fornecedorController.text.trim(),
      valorUnitario: valorUnitario,
      valorTotal: valorUnitario != null
          ? valorUnitario * widget.material.quantidade
          : null,
      dataCompra: _dataCompra,
      dataPrevisaoEntrega: _dataPrevisao,
      // usuarioId: pode pegar do auth se quiser
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (sucesso) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Status atualizado com sucesso!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao atualizar status"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}