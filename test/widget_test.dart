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
      of: find.byKey(const ValueKey('paletteList')),
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

Offset _floorPointToCanvas(WidgetTester tester, double x, double y) {
  final size = _canvasRender(tester).size;
  final horizon = size.height * 0.14;
  final kv = (size.height * 0.96 - horizon) * 2 / 1.7;
  final d = 52 - y;
  return Offset(size.width / 2 + kv * x / d, horizon + kv * 1.7 / d);
}

Offset _elementBase(WidgetTester tester, StageElement element) =>
    _floorPointToCanvas(tester, element.position.dx, element.position.dy);

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
      of: find.byKey(const ValueKey('paletteList')),
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

  testWidgets('Панель выделения: поворот и изменение размеров',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IpscDesignerApp()));
    await tester.pumpAndSettle();
    await _placeStandart(tester);
    final origin = _canvasOrigin(tester);
    await tester.tapAt(origin + const Offset(400, 400));
    await tester.pumpAndSettle();

    final toolbar = find.byKey(const ValueKey('selectionToolbar'));
    final addIcons = find.descendant(of: toolbar, matching: find.byIcon(Icons.add));
    final removeIcons = find.descendant(of: toolbar, matching: find.byIcon(Icons.remove));

    await tester.tap(find.descendant(of: toolbar, matching: find.byIcon(Icons.keyboard_double_arrow_right)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: toolbar, matching: find.byIcon(Icons.keyboard_double_arrow_right)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: toolbar, matching: find.byIcon(Icons.keyboard_double_arrow_right)));
    await tester.pumpAndSettle();
    expect(_canvasElements(tester).single.pitch, 30);

    await tester.tap(find.descendant(of: toolbar, matching: find.byIcon(Icons.keyboard_double_arrow_left)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: toolbar, matching: find.byIcon(Icons.keyboard_double_arrow_left)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: toolbar, matching: find.byIcon(Icons.keyboard_double_arrow_left)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: toolbar, matching: find.byIcon(Icons.keyboard_double_arrow_left)));
    await tester.pumpAndSettle();
    expect(_canvasElements(tester).single.pitch, -10);

    await tester.tap(find.descendant(of: toolbar, matching: find.byIcon(Icons.restart_alt)));
    await tester.pumpAndSettle();
    expect(_canvasElements(tester).single.pitch, 0);

    await tester.tap(addIcons.first);
    await tester.pumpAndSettle();
    expect(_canvasElements(tester).single.width, moreOrLessEquals(0.50, epsilon: 0.0001));

    await tester.tap(removeIcons.first);
    await tester.pumpAndSettle();
    expect(_canvasElements(tester).single.width, moreOrLessEquals(0.45, epsilon: 0.0001));

    await tester.tap(addIcons.last);
    await tester.pumpAndSettle();
    expect(_canvasElements(tester).single.height, moreOrLessEquals(0.85, epsilon: 0.0001));

    await tester.tap(removeIcons.last);
    await tester.pumpAndSettle();
    expect(_canvasElements(tester).single.height, moreOrLessEquals(0.80, epsilon: 0.0001));
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
    final firstElement = _canvasElements(tester).first;

    await tester.tapAt(origin + const Offset(460, 400));
    await tester.pumpAndSettle();
    expect(_canvasElements(tester), hasLength(2));

    await tester.tapAt(origin + _elementBase(tester, firstElement) - const Offset(0, 6));
    await tester.pumpAndSettle();
    expect(_canvasElements(tester), hasLength(2));

    final before = _canvasElements(tester).first.position;
    await tester.dragFrom(
      origin + _elementBase(tester, _canvasElements(tester).first) - const Offset(0, 10),
      const Offset(0, -120),
    );
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
    final first = _canvasElements(tester).first;

    await tester.tapAt(origin + _floorPointToCanvas(tester, 0.42, first.position.dy));
    await tester.pumpAndSettle();
    expect(_canvasElements(tester), hasLength(2));

    final dragStart = origin + _elementBase(tester, _canvasElements(tester).last) - const Offset(0, 5);
    await tester.dragFrom(dragStart, const Offset(40, 0));
    await tester.pumpAndSettle();
    final secondElement = _canvasElements(tester).last;
    final second = secondElement.position;
    expect(
      second.dx,
      moreOrLessEquals(first.position.dx + first.width / 2 + secondElement.width / 2, epsilon: 0.0001),
    );
    expect(second.dy, moreOrLessEquals(first.position.dy, epsilon: 0.0001));

    final dragStart2 = origin + _elementBase(tester, _canvasElements(tester).last) - const Offset(0, 5);
    await tester.dragFrom(dragStart2, const Offset(0, -150));
    await tester.pumpAndSettle();
    final released = _canvasElements(tester).last.position;
    expect(
      (released - second).distance,
      greaterThan(1.0),
    );
  });
}
