import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:image_converter_example/main.dart';

void main() {
  testWidgets('switching to the custom theme changes labels', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Images → PDF'), findsOneWidget);
    expect(find.text('PDF → Images'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Make PDF'), findsOneWidget);
    expect(find.text('Extract pages'), findsOneWidget);
  });
}
