import 'dart:ui' show TextDirection;

import 'package:flutter_test/flutter_test.dart';

import 'package:focusx/app.dart';

void main() {
  testWidgets('starts in Arabic RTL and opens the dashboard', (tester) async {
    await tester.pumpWidget(const FocusXApp());

    expect(
      Directionality.of(tester.element(find.text('حياة رقمية أكثر توازناً'))),
      TextDirection.rtl,
    );

    await tester.tap(find.text('ابدأ رحلتك'));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('بيانات تجريبية'), findsWidgets);
  });

  testWidgets('switches onboarding to English LTR', (tester) async {
    await tester.pumpWidget(const FocusXApp());

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(
        tester.element(find.text('A more balanced digital life')),
      ),
      TextDirection.ltr,
    );
    expect(find.text('Get started'), findsOneWidget);
  });
}
