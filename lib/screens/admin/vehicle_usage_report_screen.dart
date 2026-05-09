// lib/screens/admin/vehicle_usage_report_screen.dart (exemplo)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/vehicle.dart';
import '../../models/employee.dart';
import '../../providers/vehicle_provider.dart';

class VehicleUsageReportScreen extends StatefulWidget {
  const VehicleUsageReportScreen({super.key});

  @override
  State<VehicleUsageReportScreen> createState() => _VehicleUsageReportScreenState();
}

class _VehicleUsageReportScreenState extends State<VehicleUsageReportScreen> {
  List<Map<String, dynamic>> _usageLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsageLogs();
  }

  Future<void> _loadUsageLogs() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('vehicle_fuel_logs')
          .select('*, vehicle:vehicles(modelo, placa), technician:employees(name)')
          .order('fuel_date', ascending: false);

      setState(() {
        _usageLogs = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar logs: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Utilização de Veículos'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _usageLogs.isEmpty
          ? const Center(child: Text('Nenhum abastecimento registrado'))
          : ListView.builder(
        itemCount: _usageLogs.length,
        itemBuilder: (context, index) {
          final log = _usageLogs[index];
          final vehicle = log['vehicle'] ?? {};
          final technician = log['technician'] ?? {};

          final kmRodado = log['odometer'] != null && vehicle['odometro_inicial'] != null
              ? log['odometer'] - vehicle['odometro_inicial']
              : null;

          return ListTile(
            leading: const Icon(Icons.local_gas_station, color: Colors.orange),
            title: Text('${vehicle['modelo'] ?? 'N/D'} - ${vehicle['placa'] ?? 'N/D'}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Técnico: ${technician['name'] ?? 'N/D'}'),
                Text('Abastecido em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(log['fuel_date']))}'),
                Text('Valor: R\$ ${log['amount']?.toStringAsFixed(2) ?? '0.00'}'),
                Text('KM atual: ${log['odometer'] ?? 'N/D'}'),
                if (kmRodado != null) Text('KM rodado: $kmRodado km'),
                if (log['card_number'] != null) Text('Cartão: ${log['card_number']}'),
                if (log['receipt_url'] != null)
                  TextButton(
                    onPressed: () {
                      // Abrir imagem do comprovante
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewer(url: log['receipt_url'])));
                    },
                    child: const Text('Ver comprovante'),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: _loadUsageLogs,
      ),
    );
  }
}