// Leonardo Moya Fernandes, Vinicius Silvestre
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _integrantes = 'Leonardo Moya Fernandes, Vinicius Silvestre';

void main() {
  runApp(const MyApp());
}

class Livro {
  Livro({required this.titulo, required this.autor, required this.status});

  final String titulo;
  final String autor;
  String status;

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'autor': autor,
    'status': status,
  };

  factory Livro.fromJson(Map<String, dynamic> json) {
    return Livro(
      titulo: json['titulo'] as String,
      autor: json['autor'] as String,
      status: json['status'] as String,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Organização de Leituras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ListaLivrosPage(),
    );
  }
}

class ListaLivrosPage extends StatefulWidget {
  const ListaLivrosPage({super.key});

  @override
  State<ListaLivrosPage> createState() => _ListaLivrosPageState();
}

class _ListaLivrosPageState extends State<ListaLivrosPage> {
  static const _storageKey = 'livros';
  List<Livro> _livros = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarLivros();
  }

  Future<void> _carregarLivros() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getStringList(_storageKey) ?? [];

    setState(() {
      _livros = dados
          .map(
            (item) => Livro.fromJson(jsonDecode(item) as Map<String, dynamic>),
          )
          .toList();
      _carregando = false;
    });
  }

  Future<void> _salvarLivros() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = _livros.map((livro) => jsonEncode(livro.toJson())).toList();
    await prefs.setStringList(_storageKey, dados);
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _abrirCadastro() async {
    final novoLivro = await Navigator.push<Livro>(
      context,
      MaterialPageRoute(builder: (context) => const CadastroLivroPage()),
    );

    if (novoLivro != null) {
      setState(() => _livros.add(novoLivro));
      await _salvarLivros();
      _mostrarMensagem('Livro cadastrado com sucesso.');
    }
  }

  Future<void> _removerLivro(int index) async {
    final removido = _livros[index];
    setState(() => _livros.removeAt(index));
    await _salvarLivros();
    _mostrarMensagem('"${removido.titulo}" foi removido.');
  }

  Future<void> _alterarStatus(int index, String novoStatus) async {
    setState(() => _livros[index].status = novoStatus);
    await _salvarLivros();
    _mostrarMensagem('Status atualizado.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Organização de Leituras'),
            Text(_integrantes, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _livros.isEmpty
          ? const Center(
              child: Text(
                'Nenhum livro cadastrado.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _livros.length,
              itemBuilder: (context, index) {
                final livro = _livros[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      livro.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Autor: ${livro.autor}'),
                          const SizedBox(height: 6),
                          DropdownButton<String>(
                            value: livro.status,
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(
                                value: 'Quero ler',
                                child: Text('Quero ler'),
                              ),
                              DropdownMenuItem(
                                value: 'Lendo',
                                child: Text('Lendo'),
                              ),
                              DropdownMenuItem(
                                value: 'Concluído',
                                child: Text('Concluído'),
                              ),
                            ],
                            onChanged: (valor) {
                              if (valor != null) {
                                _alterarStatus(index, valor);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Remover',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removerLivro(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCadastro,
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar livro'),
      ),
    );
  }
}

class CadastroLivroPage extends StatefulWidget {
  const CadastroLivroPage({super.key});

  @override
  State<CadastroLivroPage> createState() => _CadastroLivroPageState();
}

class _CadastroLivroPageState extends State<CadastroLivroPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _autorController = TextEditingController();
  String _status = 'Quero ler';

  @override
  void dispose() {
    _tituloController.dispose();
    _autorController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(
        context,
        Livro(
          titulo: _tituloController.text.trim(),
          autor: _autorController.text.trim(),
          status: _status,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cadastrar livro'),
            Text(_integrantes, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe o título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _autorController,
                decoration: const InputDecoration(
                  labelText: 'Autor',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe o autor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status da leitura',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Quero ler',
                    child: Text('Quero ler'),
                  ),
                  DropdownMenuItem(value: 'Lendo', child: Text('Lendo')),
                  DropdownMenuItem(
                    value: 'Concluído',
                    child: Text('Concluído'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => _status = valor);
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save),
                label: const Text('Salvar livro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
