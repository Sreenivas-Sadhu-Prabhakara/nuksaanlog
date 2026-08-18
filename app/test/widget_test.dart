import 'package:flutter_test/flutter_test.dart';

import 'package:nuksaanlog_app/main.dart';

void main() {
  test('ranked lists items by rupee loss, worst first', () {
    final r = ranked([Loss('milk', 5, 40, 'spoiled'), Loss('bread', 10, 25, 'expired'), Loss('milk', 2, 40, 'spoiled')]);
    expect(r.first.key, 'milk');
    expect(r.first.value, closeTo(280, 1e-9));
  });

  testWidgets('renders total lost', (tester) async {
    await tester.pumpWidget(const NuksaanlogApp());
    expect(find.textContaining('Total lost'), findsOneWidget);
  });
}
