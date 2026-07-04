import 'package:flutter_test/flutter_test.dart';

import 'package:revive_spring/main.dart';

void main() {
  testWidgets('ReviveSpring starts on the branded splash screen', (tester) async {
    await tester.pumpWidget(const ReviveSpringApp());

    expect(find.text('REVIVESPRING'), findsOneWidget);
    expect(find.text('Revive Your Spirit. Renew Your Day.'), findsOneWidget);
  });
}
