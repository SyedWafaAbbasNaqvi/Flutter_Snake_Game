import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snake_game/main.dart';

void main() {
  testWidgets('Snake game smoke test loads game screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SnakeGameApp()));
    expect(find.text('Snake Game 🐍'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.text('LENGTH'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2)); // SCORE: 0 and BEST: 0
  });
}
