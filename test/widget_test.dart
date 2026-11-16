import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:mobile_ipsc_designer_app/main.dart';

void main() {
  testWidgets('Библиотека стейджей открывается', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IpscDesignerApp()));
    await tester.pumpAndSettle();

    expect(find.text('Библиотека стейджей'), findsOneWidget);
    expect(
      find.text('Стейджей пока нет. Нажмите «Создать».'),
      findsOneWidget,
    );
  });

  testWidgets('Редактор: меню инструментов, подтверждение и установка',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IpscDesignerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();

    expect(find.text('Новый стейдж'), findsOneWidget);
    expect(find.text('Поппер'), findsNothing);

    await tester.tap(find.byIcon(Icons.construction));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Поппер'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Поставить'));
    await tester.pumpAndSettle();

    expect(find.text('Поппер'), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsNothing);
  });
}
