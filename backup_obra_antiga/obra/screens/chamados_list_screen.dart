// lib/features/obra/screens/chamados_list_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'chamado_form_screen.dart';

class ChamadosListScreen extends StatefulWidget {
  final String? obraId;        // ← Agora pode receber o ID da obra
  final String? obraNome;

  const ChamadosListScreen({
    super.key,
    this.obraId,
    this.obraNome,
  });

  @override
  State<ChamadosListScreen> createState() => _ChamadosListScreenState();
}

class _ChamadosListScreenState extends State<ChamadosListScreen> {
  List<Map<String, dynamic>> _chamados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarChamados();
  }

  Future<void> _carregarChamados() async {
    setState(() => _isLoading = true);
    try {
      var query = Supabase.instance.client
          .from('chamados')
          .select('*, obra:obras(name)');

      // Se veio de uma obra específica, filtra
      if (widget.obraId != null) {
        query = query.eq('obra_id', widget.obraId!);   // ← Adicionado o "!"
      }

      final response = await query.order('data_criacao', ascending: false);

      setState(() {
        _chamados = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Erro ao carregar chamados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.obraNome != null
            ? Text('Chamados - ${widget.obraNome}')
            : const Text('Meus Chamados'),
        backgroundColor: Colors.teal[900],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chamados.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhum chamado encontrado', style: TextStyle(fontSize: 18)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _chamados.length,
        itemBuilder: (context, index) {
          final chamado = _chamados[index];
          final status = chamado['status'] ?? 'pendente';
          final color = status == 'concluido' ? Colors.green : status == 'em_andamento' ? Colors.orange : Colors.blue;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.assignment, color: color, size: 40),
              title: Text(chamado['titulo'] ?? 'Sem título', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Obra: ${chamado['obra']?['name'] ?? '—'}'),
                  if (chamado['data_agendada'] != null)
                    Text('Agendado: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(chamado['data_agendada']))}'),
                ],
              ),
              trailing: Chip(
                label: Text(status.toUpperCase()),
                backgroundColor: color.withOpacity(0.2),
                labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Abrindo: ${chamado['titulo']}')),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChamadoFormScreen(
                obraId: widget.obraId ?? 'obra-teste-id',   // Usa o ID passado ou fallback
                obraNome: widget.obraNome ?? 'Obra Atual',
              ),
            ),
          );

          if (result == true) {
            _carregarChamados(); // Atualiza a lista
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}