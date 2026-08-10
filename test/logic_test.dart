import 'package:flutter_test/flutter_test.dart';
import 'package:mathmemoryplanet/models.dart';

String _sig(Level l) {
  final String cards = l.cards.map((CardItem c) => '${c.label}:${c.pairId}').join(',');
  return '${l.rows}|${l.cols}|${l.target}|${l.previewMs}|$cards|${l.sequence.join(',')}|${l.numbers.join(',')}|${l.targets.join(',')}';
}

void main() {
  group('level generator', () {
    test('deterministic: same input builds the identical level', () {
      for (final GameMode mode in GameMode.values) {
        for (int i = 0; i < 30; i += 7) {
          expect(_sig(buildLevel(mode, i)), _sig(buildLevel(mode, i)));
        }
      }
    });

    test('unique: consecutive levels always differ', () {
      for (final GameMode mode in GameMode.values) {
        for (int i = 0; i < 29; i++) {
          expect(
            _sig(buildLevel(mode, i)) == _sig(buildLevel(mode, i + 1)),
            isFalse,
            reason: '$mode level $i',
          );
        }
      }
    });

    test('flip modes: grid fits exactly, every pairId appears twice', () {
      for (final GameMode mode in <GameMode>[GameMode.pairs, GameMode.eqMatch, GameMode.targetSum]) {
        for (int i = 0; i < 30; i++) {
          final Level l = buildLevel(mode, i);
          expect(l.cards.length, l.rows * l.cols);
          final Map<int, int> counts = <int, int>{};
          for (final CardItem c in l.cards) {
            counts[c.pairId] = (counts[c.pairId] ?? 0) + 1;
          }
          counts.forEach((int k, int v) => expect(v, 2));
        }
      }
    });

    test('targetSum: every generated pair sums to the target', () {
      for (int i = 0; i < 30; i++) {
        final Level l = buildLevel(GameMode.targetSum, i);
        final Map<int, List<int>> byPair = <int, List<int>>{};
        for (final CardItem c in l.cards) {
          byPair.putIfAbsent(c.pairId, () => <int>[]).add(int.parse(c.label));
        }
        byPair.forEach((int k, List<int> v) {
          expect(v.length, 2);
          expect(v[0] + v[1], l.target);
        });
      }
    });

    test('eqMatch: answers are unique within a level', () {
      for (int i = 0; i < 30; i++) {
        final Level l = buildLevel(GameMode.eqMatch, i);
        final Set<String> answers = <String>{};
        for (final CardItem c in l.cards) {
          if (!c.label.contains('+') && !c.label.contains('-') && !c.label.contains('×')) {
            expect(answers.add(c.label), isTrue, reason: 'duplicate answer ${c.label} at level $i');
          }
        }
      }
    });

    test('hidden: grid fits, numbers distinct, targets are a subset', () {
      for (int i = 0; i < 30; i++) {
        final Level l = buildLevel(GameMode.hidden, i);
        expect(l.numbers.length, l.rows * l.cols);
        expect(l.numbers.toSet().length, l.numbers.length);
        expect(l.targets.length, i ~/ 10 + 1);
        for (final int t in l.targets) {
          expect(l.numbers.contains(t), isTrue);
        }
      }
    });

    test('order: grid fits, numbers distinct', () {
      for (int i = 0; i < 30; i++) {
        final Level l = buildLevel(GameMode.order, i);
        expect(l.numbers.length, l.rows * l.cols);
        expect(l.numbers.toSet().length, l.numbers.length);
      }
    });

    test('builder: equation is arithmetically valid', () {
      for (int i = 0; i < 30; i++) {
        final Level l = buildLevel(GameMode.builder, i);
        expect(l.cards.length, 4);
        final List<String> byId = List<String>.filled(4, '');
        for (final CardItem c in l.cards) {
          byId[c.pairId] = c.label;
        }
        final int a = int.parse(byId[0]);
        final int b = int.parse(byId[2]);
        final int c = int.parse(byId[3]);
        final String op = byId[1];
        if (op == '+') {
          expect(a + b, c);
        } else if (op == '-') {
          expect(a - b, c);
        } else {
          expect(a * b, c);
        }
      }
    });

    test('sequence: tiles valid, length in range, no adjacent repeats', () {
      for (int i = 0; i < 30; i++) {
        final Level l = buildLevel(GameMode.sequence, i);
        expect(l.sequence.length >= 3, isTrue);
        expect(l.sequence.length <= 10, isTrue);
        for (int k = 0; k < l.sequence.length; k++) {
          expect(l.sequence[k] >= 0 && l.sequence[k] < 9, isTrue);
          if (k > 0) {
            expect(l.sequence[k] == l.sequence[k - 1], isFalse);
          }
        }
      }
    });
  });
}
