// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:dairy_f/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders navigation items', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('今天'), findsOneWidget);
    expect(find.text('打卡'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}
