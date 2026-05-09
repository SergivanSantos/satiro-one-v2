// lib/screens/settings/ponto_config_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PontoConfigScreen extends StatefulWidget {
  const PontoConfigScreen({super.key});

  @override
  State<PontoConfigScreen> createState() => _PontoConfigScreenState();
}

class _PontoConfigScreenState extends State<PontoConfigScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _config = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final response = await Supabase.instance.client
          .from('ponto_config')
          .select('config_json')
          .limit(1)
          .maybeSingle();

      setState(() {
        _config = response?['config_json'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar config: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de Ponto'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Jornada por dia da semana'),
              subtitle: Text(_config['dias_semana'] != null ? 'Configurado' : 'Não configurado'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                // Futuro: tela para editar jornadas seg-dom
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edição de jornada em desenvolvimento')));
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_busy),
              title: const Text('Feriados'),
              subtitle: const Text('Adicionar/excluir feriados nacionais/regionais'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerenciamento de feriados em desenvolvimento')));
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Vale-refeição'),
              subtitle: Text('Valor: R\$ ${_config['vale_refeicao']?['valor_por_dia'] ?? 'Não configurado'}'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuração de VR em desenvolvimento')));
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.hourglass_empty),
              title: const Text('Banco de horas e HE'),
              subtitle: const Text('Regras de 50%/100%, limite diário, compensação'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regras de banco de horas em desenvolvimento')));
              },
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Salvar Configurações'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvamento em desenvolvimento')));
            },
          ),
        ],
      ),
    );
  }
}