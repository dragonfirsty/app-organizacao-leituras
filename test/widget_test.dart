import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_organizacao_leituras/main.dart';

void main() {
  testWidgets('exibe a tela inicial e o botao de cadastro', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Organização de Leituras'), findsOneWidget);
    expect(find.text('Nenhum livro cadastrado.'), findsOneWidget);
    expect(find.text('Cadastrar livro'), findsOneWidget);
  });
}
