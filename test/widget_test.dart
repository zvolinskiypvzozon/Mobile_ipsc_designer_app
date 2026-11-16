import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ipsc_designer_app/main.dart';

void main() {
  testWidgets('Stage library renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IpscDesignerApp()));

    expect(find.text('Stage library'), findsOneWidget);
    expect(find.text('No stages yet. Tap + to create one.'), findsOneWidget);
  });
}
