// lib/checklist/vehicles_operacional_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/vehicle_provider.dart';
import '../models/vehicle.dart';

class VehiclesOperacionalTab extends StatelessWidget {
  const VehiclesOperacionalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        if (vehicleProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.teal));
        }

        if (vehicleProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Erro: ${vehicleProvider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  onPressed: () => vehicleProvider.fetchVehicles(context),
                ),
              ],
            ),
          );
        }

        final vehicles = vehicleProvider.vehicles;

        if (vehicles.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum veículo cadastrado',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => vehicleProvider.fetchVehicles(context),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.teal[50]),
                dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) return Colors.teal[100];
                  return null;
                }),
                columnSpacing: 20,
                horizontalMargin: 16,
                columns: const [
                  DataColumn(label: Text('Placa', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Modelo', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Técnico', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Retirada', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: vehicles.map((v) {
                  final emUso = v.idTecnico != null;
                  final statusColor = emUso
                      ? Colors.orange[800]!
                      : (v.status == 'manutencao' ? Colors.amber[800]! : Colors.green[800]!);

                  return DataRow(
                    color: WidgetStateProperty.all(emUso ? Colors.orange[50] : Colors.green[50]),
                    cells: [
                      DataCell(
                        Text(
                          v.placa.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(Text(v.modelo)),
                      DataCell(
                        Tooltip(
                          message: v.status == 'em_uso'
                              ? 'Em uso por técnico'
                              : v.status == 'manutencao'
                              ? 'Em manutenção'
                              : 'Disponível',
                          child: Text(
                            v.status == 'em_uso' ? 'Em uso' : v.status == 'manutencao' ? 'Manutenção' : 'Disponível',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          emUso ? 'Técnico ${v.idTecnico}' : 'Disponível',
                          style: TextStyle(color: emUso ? Colors.orange[900] : Colors.green[900]),
                        ),
                      ),
                      DataCell(
                        Text(
                          v.formatDataRetirada(),
                          style: TextStyle(
                            color: emUso ? Colors.orange[900] : Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}