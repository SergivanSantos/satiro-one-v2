// lib/screens/time_tracking/time_clock_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import '../../providers/ponto_provider.dart';

class TimeClockScreen extends StatefulWidget {
  const TimeClockScreen({super.key});

  @override
  State<TimeClockScreen> createState() => _TimeClockScreenState();
}

class _TimeClockScreenState extends State<TimeClockScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('[TIME CLOCK SCREEN] initState chamado - preparando carregamento de hoje');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = Provider.of<EmployeeProvider>(context, listen: false).currentEmployee;
      if (employee != null) {
        print('[TIME CLOCK SCREEN] Iniciando carregarRegistrosHoje para employeeId: ${employee.id}');
        Provider.of<PontoProvider>(context, listen: false).carregarRegistrosHoje(employee.id!);
      } else {
        print('[TIME CLOCK SCREEN] Nenhum employee encontrado no initState');
      }
    });
  }

  Future<bool> _checkGpsPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ative a localização para bater ponto')));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissão de localização negada')));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissão bloqueada permanentemente. Ative nas configurações.')));
      return false;
    }
    return true;
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao obter localização: $e')));
      return null;
    }
  }

  Future<void> _registerPonto(String type) async {
    setState(() => _isLoading = true);

    final employee = Provider.of<EmployeeProvider>(context, listen: false).currentEmployee;
    if (employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum funcionário logado')));
      setState(() => _isLoading = false);
      return;
    }

    if (!await _checkGpsPermission()) {
      setState(() => _isLoading = false);
      return;
    }

    final position = await _getCurrentPosition();
    if (position == null) {
      setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now().toLocal();

    try {
      final insertData = <String, dynamic>{
        'employee_id': employee.id!,
        'entry_type': type,
        'timestamp': now.toUtc().toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'created_by': employee.id!,
      };

      if (employee.branchId != null) {
        insertData['branch_id'] = employee.branchId;
      }

      await supabase.from('time_entries').insert(insertData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type registrada às ${DateFormat('HH:mm').format(now)}'),
          backgroundColor: Colors.green,
        ),
      );

      // Atualiza imediatamente os registros de hoje
      print('[TIME CLOCK SCREEN] Registro de $type feito - recarregando registros de hoje');
      Provider.of<PontoProvider>(context, listen: false).carregarRegistrosHoje(employee.id!);

    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Este ponto de $type já foi registrado hoje!'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  void _openHistory() async {
    final employee = Provider.of<EmployeeProvider>(context, listen: false).currentEmployee;
    if (employee == null) return;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) return;

    print('[TIME CLOCK SCREEN] Usuário selecionou data: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');
    Provider.of<PontoProvider>(context, listen: false)
        .carregarRegistrosPorData(employee.id!, selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PontoProvider>(
      builder: (context, pontoProvider, child) {
        print('[TIME CLOCK SCREEN] Consumer rebuild - registrosHoje length: ${pontoProvider.registrosHoje.length}');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bater Ponto'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Ver histórico',
                onPressed: _openHistory,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sair?'),
                      content: const Text('Deseja realmente sair do sistema?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sair', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await Provider.of<EmployeeProvider>(context, listen: false).logout();
                    if (mounted) Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: pontoProvider.jaBateuEntradaHoje ? null : () => _registerPonto('entrada'),
                  icon: const Icon(Icons.login),
                  label: Text(pontoProvider.jaBateuEntradaHoje
                      ? 'Entrada: ${pontoProvider.horarioEntradaHoje ?? ""}'
                      : 'Entrada'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(220, 60)),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: pontoProvider.jaBateuSaidaAlmocoHoje ? null : () => _registerPonto('saida_almoco'),
                  icon: const Icon(Icons.restaurant),
                  label: Text(pontoProvider.jaBateuSaidaAlmocoHoje
                      ? 'Saída almoço: ${pontoProvider.horarioSaidaAlmocoHoje ?? ""}'
                      : 'Saída almoço'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(220, 60)),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: pontoProvider.jaBateuRetornoAlmocoHoje ? null : () => _registerPonto('retorno_almoco'),
                  icon: const Icon(Icons.restaurant_menu),
                  label: Text(pontoProvider.jaBateuRetornoAlmocoHoje
                      ? 'Retorno almoço: ${pontoProvider.horarioRetornoAlmocoHoje ?? ""}'
                      : 'Retorno almoço'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(220, 60)),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: pontoProvider.jaBateuSaidaHoje ? null : () => _registerPonto('saida'),
                  icon: const Icon(Icons.logout),
                  label: Text(pontoProvider.jaBateuSaidaHoje
                      ? 'Saída: ${pontoProvider.horarioSaidaHoje ?? ""}'
                      : 'Saída'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(220, 60)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}