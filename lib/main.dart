// Leonardo Moya Fernandes, Vinicius Silvestre
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _integrantes = 'Leonardo Moya Fernandes, Vinicius Silvestre';

void main() {
  runApp(const MyApp());
}

class Livro {
  Livro({
    required this.titulo,
    required this.autor,
    required this.status,
    this.nota,
    this.opiniao = '',
  });

  final String titulo;
  final String autor;
  String status;
  int? nota;
  String opiniao;

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'autor': autor,
    'status': status,
    'nota': nota,
    'opiniao': opiniao,
  };

  factory Livro.fromJson(Map<String, dynamic> json) {
    return Livro(
      titulo: json['titulo'] as String,
      autor: json['autor'] as String,
      status: json['status'] as String,
      nota: json['nota'] as int?,
      opiniao: json['opiniao'] as String? ?? '',
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
  final TextEditingController _buscaController = TextEditingController();
  String _busca = '';
  String _statusFiltro = 'Todos';

  @override
  void initState() {
    super.initState();
    _carregarLivros();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
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

  Future<void> _alterarNota(int index, int nota) async {
    setState(() => _livros[index].nota = nota);
    await _salvarLivros();
  }

  Future<void> _alterarOpiniao(int index, String opiniao) async {
    _livros[index].opiniao = opiniao;
    await _salvarLivros();
  }

  List<int> get _indicesFiltrados {
    final busca = _busca.trim().toLowerCase();

    return List.generate(_livros.length, (index) => index).where((index) {
      final livro = _livros[index];
      final correspondeBusca =
          busca.isEmpty ||
          livro.titulo.toLowerCase().contains(busca) ||
          livro.autor.toLowerCase().contains(busca);
      final correspondeStatus =
          _statusFiltro == 'Todos' || livro.status == _statusFiltro;

      return correspondeBusca && correspondeStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final indicesFiltrados = _indicesFiltrados;
    final totalLivros = _livros.length;
    final totalQueroLer = _livros
        .where((livro) => livro.status == 'Quero ler')
        .length;
    final totalLendo = _livros
        .where((livro) => livro.status == 'Lendo')
        .length;
    final totalConcluidos = _livros
        .where((livro) => livro.status == 'Concluído')
        .length;

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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ResumoEstanteItem(
                              valor: totalLivros,
                              titulo: 'Total',
                            ),
                          ),
                          Expanded(
                            child: _ResumoEstanteItem(
                              valor: totalQueroLer,
                              titulo: 'Quero ler',
                            ),
                          ),
                          Expanded(
                            child: _ResumoEstanteItem(
                              valor: totalLendo,
                              titulo: 'Lendo',
                            ),
                          ),
                          Expanded(
                            child: _ResumoEstanteItem(
                              valor: totalConcluidos,
                              titulo: 'Concluídos',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: TextField(
                    controller: _buscaController,
                    decoration: InputDecoration(
                      labelText: 'Buscar por título ou autor',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _busca.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _buscaController.clear();
                                setState(() => _busca = '');
                              },
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (valor) {
                      setState(() => _busca = valor);
                    },
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: const [
                      _FiltroChip(status: 'Todos'),
                      SizedBox(width: 8),
                      _FiltroChip(status: 'Quero ler'),
                      SizedBox(width: 8),
                      _FiltroChip(status: 'Lendo'),
                      SizedBox(width: 8),
                      _FiltroChip(status: 'Concluído'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: indicesFiltrados.isEmpty
                      ? Center(
                          child: Text(
                            _livros.isEmpty
                                ? 'Nenhum livro cadastrado.'
                                : 'Nenhum livro encontrado.',
                            style: const TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: indicesFiltrados.length,
                          itemBuilder: (context, posicao) {
                            final index = indicesFiltrados[posicao];
                            final livro = _livros[index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                  livro.titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      if (livro.status == 'Concluído') ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Nota',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (estrela) {
                                            final numero = estrela + 1;
                                            final preenchida =
                                                (livro.nota ?? 0) >= numero;

                                            return IconButton(
                                              tooltip:
                                                  '$numero ${numero == 1 ? 'estrela' : 'estrelas'}',
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(
                                                    minWidth: 36,
                                                    minHeight: 36,
                                                  ),
                                              icon: Icon(
                                                preenchida
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: preenchida
                                                    ? Colors.amber
                                                    : null,
                                              ),
                                              onPressed: () =>
                                                  _alterarNota(index, numero),
                                            );
                                          }),
                                        ),
                                        TextFormField(
                                          key: ValueKey(
                                            'opiniao-${livro.titulo}-$index',
                                          ),
                                          initialValue: livro.opiniao,
                                          maxLength: 200,
                                          maxLines: 3,
                                          minLines: 1,
                                          decoration:
                                              const InputDecoration(
                                                labelText:
                                                    'Comentário curto',
                                                hintText:
                                                    'Escreva sua opinião',
                                                border: OutlineInputBorder(),
                                              ),
                                          onChanged: (valor) =>
                                              _alterarOpiniao(index, valor),
                                        ),
                                      ],
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
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCadastro,
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar livro'),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final pageState = context.findAncestorStateOfType<_ListaLivrosPageState>();

    return ChoiceChip(
      label: Text(status),
      selected: pageState?._statusFiltro == status,
      onSelected: (selecionado) {
        if (selecionado) {
          pageState?.setState(() => pageState._statusFiltro = status);
        }
      },
    );
  }
}

class _ResumoEstanteItem extends StatelessWidget {
  const _ResumoEstanteItem({required this.valor, required this.titulo});

  final int valor;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$valor',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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
