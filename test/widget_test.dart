import 'package:flutter_test/flutter_test.dart';

import 'package:lab_s13_s14_crud/main.dart';

// Prueba básica: la app arranca y muestra el título
void main() {
  testWidgets('Muestra el título Mis tareas', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Mis tareas'), findsOneWidget);
  });
}
