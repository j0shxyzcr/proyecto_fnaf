import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fnaf_blog_rojo/main.dart';

void main() {
  testWidgets('muestra la pantalla de inicio de sesion', (tester) async {
    await tester.pumpWidget(const BlogFnaf());

    expect(find.text('FNAF BLOG'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('renderiza la navegacion principal sin excepciones', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaPrincipal(nombre: 'Prueba', alSalir: () {}),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Comunidad'), findsOneWidget);
    expect(find.text('Tienda'), findsOneWidget);
  });
}
