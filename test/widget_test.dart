import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:mobile_ipsc_designer_app/core/models/stage_element.dart';
import 'package:mobile_ipsc_designer_app/main.dart';

const ValueKey<String> _canvasKey = ValueKey('galleryCanvas');

RenderCustomPaint _canvasRender(WidgetTester tester) =>
    tester.renderObject<RenderCustomPaint>(find.byKey(_canvasKey));

List<StageElement> _canvasElements(WidgetTester tester) =>
    (_canvasRender(tester).painter as dynamic).elements as List<StageElement>;

Future<void> _placeStandart(WidgetTester tester) async {
  await tester.tap(find.text('Создать'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.construction));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('IPSC Standart'),
    64,
    scrollable: find.descendant(
      of: find.widgetWithText(ListView, 'Библиотека пропов'),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('IPSC Standart'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Поставить'));
  await tester.pumpAndSettle();
}

Offset _canvasOrigin(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(_canvasKey));

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

    await tester.scrollUntilVisible(
      find.text('Поппер'),
      64,
      scrollable: find.descendant(
        of: find.widgetWithText(ListView, 'Библиотека пропов'),
        matching: find.byType(Scrollable),
      ),
    );
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

  testWidgets('Стрелки клавиатуры двигают выделенную мишень',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IpscDesignerApp()));
    await tester.pumpAndSettle();
    await _placeStandart(tester);
    final origin = _canvasOrigin(tester);
    await tester.tapAt(origin + const Offset(400, 400));
    await tester.pumpAndSettle();
    expect(_canvasElements(tester), hasLength(1));

    final before = _canvasElements(tester).single.position;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(
      _canvasElements(tester).single.position.dy,
      lessThan(before.dy),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      _canvasElements(tester).single.position.dy,
      moreOrLessEquals(before.dy, epsilon: 0.0001),
    );
  });

  testWidgets('Тап по существующей мишени не создаёт дубликат, старые двигаются',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IpscDesignerApp()));
    await tester.pumpAndSettle();
    await _placeStandart(tester);
    final origin = _canvasOrigin(tester);
    await tester.tapAt(origin + const Offset(400, 400));
    await tester.pumpAndSettle();

    await tester.tapAt(origin + const Offset(460, 440));
    await tester.pumpAndSettle();
    expect(_canvasElements(tester), hasLength(2));

    await tester.tapAt(origin + const Offset(400, 400));
    await tester.pumpAndSettle();
    expect(_canvasElements(tester), hasLength(2));

    final before = _canvasElements(tester).first.position;
    await tester.dragFrom(origin + const Offset(400, 395), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(_canvasElements(tester), hasLength(2));
    expect(
      _canvasElements(tester).first.position.dy,
      lessThan(before.dy),
    );
  });

  testWidgets('Мишень прилипает к соседней и отлипает при оттягивании',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IpscDesignerApp()));
    await tester.pumpAndSettle();
    await _placeStandart(tester);
    final origin = _canvasOrigin(tester);
    await tester.tapAt(origin + const Offset(400, 400));
    await tester.pumpAndSettle();
    final first = _canvasElements(tester).single.position;

    await tester.tapAt(origin + const Offset(484, 400));
    await tester.pumpAndSettle();
    expect(_canvasElements(tester), hasLength(2));

    await tester.dragFrom(origin + const Offset(484, 395), const Offset(40, 0));
    await tester.pumpAndSettle();
    final second = _canvasElements(tester).last.position;
    expect(second.dx, moreOrLessEquals(first.dx + 0.45, epsilon: 0.0001));
    expect(second.dy, moreOrLessEquals(first.dy, epsilon: 0.0001));

    await tester.dragFrom(origin + const Offset(488, 395), const Offset(0, -150));
    await tester.pumpAndSettle();
    final released = _canvasElements(tester).last.position;
    expect(
      (released - second).distance,
      greaterThan(1.0),
    );
  });
}
