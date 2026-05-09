import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/brand_provider.dart';
import '../models/brand.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({Key? key}) : super(key: key);

  @override
  BrandsScreenState createState() => BrandsScreenState();
}

class BrandsScreenState extends State<BrandsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addBrand() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Marca'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da Marca',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Insira o nome da marca' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final brand = Brand(name: _nameController.text);
                //await Provider.of<BrandProvider>(context, listen: false).insertBrand(brand); // Corrigido de addBrand para insertBrand
                if (mounted) {
                  _nameController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marca adicionada')),
                  );
                }
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editBrand(Brand brand) async {
    _nameController.text = brand.name;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Marca'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da Marca',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Insira o nome da marca' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final updatedBrand = Brand(id: brand.id, name: _nameController.text);
                await Provider.of<BrandProvider>(context, listen: false).updateBrand(updatedBrand);
                if (mounted) {
                  _nameController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marca atualizada')),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandProvider = Provider.of<BrandProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcas'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addBrand,
          ),
        ],
      ),
      body: brandProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : brandProvider.errorMessage != null
          ? Center(child: Text('Erro: ${brandProvider.errorMessage}'))
          : brandProvider.brands.isEmpty
          ? const Center(child: Text('Nenhuma marca encontrada'))
          : ListView.builder(
        itemCount: brandProvider.brands.length,
        itemBuilder: (context, index) {
          final brand = brandProvider.brands[index];
          return Card(
            child: ListTile(
              title: Text(brand.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.teal),
                    onPressed: () => _editBrand(brand),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Excluir Marca'),
                          content: Text('Tem certeza que deseja excluir a marca ${brand.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        await brandProvider.deleteBrand(brand.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Marca excluída')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}