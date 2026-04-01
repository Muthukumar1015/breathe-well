import 'package:flutter_test/flutter_test.dart';
import 'package:breathe/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const BreatheWellApp());
    expect(find.text('Breathe Well'), findsOneWidget);
  });
}
