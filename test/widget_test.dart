import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmemoryplanet/widgets.dart';

void main() {
  testWidgets('ChunkyButton fires its callback', (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ChunkyButton(
              onTap: () {
                taps++;
              },
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    expect(taps, 1);
  });

  testWidgets('StarBar renders filled and outline stars', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StarBar(stars: 2)),
      ),
    );
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
  });
}
