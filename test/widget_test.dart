import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:mobile_ipsc_designer_app/main.dart';

void main() {
  testWidgets('Stage library renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IpscDesignerApp()));
    await tester.pumpAndSettle();

    expect(find.text('Stage library'), findsOneWidget);
    expect(find.text('No stages yet. Tap + to create one.'), findsOneWidget);
  });

  testWidgets('Editor opens gallery, tools hide after selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IpscDesignerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New stage'));
    await tester.pumpAndSettle();

    expect(find.text('New stage'), findsOneWidget);
    expect(find.text('Paper target'), findsNothing);

    await tester.tap(find.byIcon(Icons.construction));
    await tester.pumpAndSettle();

    expect(find.text('Paper target'), findsOneWidget);

    await tester.tap(find.text('Paper target'));
    await tester.pumpAndSettle();

    expect(find.text('Paper target'), findsNWidgets(2));
  });
}
