import 'dart:math';

/// Called by a game widget when the level is completed.
typedef WinCallback = void Function(int mistakes, int moves);

/// The 7 game modes. Each is a genuinely different mechanic.
enum GameMode { pairs, eqMatch, sequence, hidden, targetSum, order, builder }

class ModeInfo {
  const ModeInfo({
    required this.mode,
    required this.emoji,
    required this.color,
    required this.titleKey,
    required this.hintKey,
  });

  final GameMode mode;
  final String emoji;
  final int color;
  final String titleKey;
  final String hintKey;
}

const List<ModeInfo> kModes = <ModeInfo>[
  ModeInfo(mode: GameMode.pairs, emoji: '🪐', color: 0xFF45B7FF, titleKey: 'mode_pairs', hintKey: 'hint_pairs'),
  ModeInfo(mode: GameMode.eqMatch, emoji: '🧮', color: 0xFF4ECDC4, titleKey: 'mode_eqmatch', hintKey: 'hint_eqmatch'),
  ModeInfo(mode: GameMode.sequence, emoji: '🚀', color: 0xFFFF6B6B, titleKey: 'mode_sequence', hintKey: 'hint_sequence'),
  ModeInfo(mode: GameMode.hidden, emoji: '🔍', color: 0xFFFFD233, titleKey: 'mode_hidden', hintKey: 'hint_hidden'),
  ModeInfo(mode: GameMode.targetSum, emoji: '🎯', color: 0xFFFF8ED4, titleKey: 'mode_target', hintKey: 'hint_target'),
  ModeInfo(mode: GameMode.order, emoji: '📈', color: 0xFF7ED957, titleKey: 'mode_order', hintKey: 'hint_order'),
  ModeInfo(mode: GameMode.builder, emoji: '🧩', color: 0xFFB9A7F9, titleKey: 'mode_builder', hintKey: 'hint_builder'),
];

class CardItem {
  const CardItem(this.label, this.pairId);

  final String label;

  /// Two cards match when they share the same pairId.
  /// For the builder mode, pairId is the correct tap order (0..3).
  final int pairId;
}

class Level {
  const Level({
    required this.mode,
    required this.index,
    this.rows = 0,
    this.cols = 0,
    this.cards = const <CardItem>[],
    this.sequence = const <int>[],
    this.numbers = const <int>[],
    this.targets = const <int>[],
    this.target = 0,
    this.previewMs = 0,
    this.par3 = 0,
    this.par2 = 0,
    this.tileCount = 9,
  });

  final GameMode mode;
  final int index;
  final int rows;
  final int cols;
  final List<CardItem> cards;
  final List<int> sequence;
  final List<int> numbers;
  final List<int> targets;
  final int target;
  final int previewMs;

  /// mistakes <= par3 -> 3 stars, mistakes <= par2 -> 2 stars, else 1 star.
  final int par3;
  final int par2;
  final int tileCount;
}

/// Pair counts per difficulty band (easy / medium / hard) and tier (0..2).
const List<List<int>> _pairsByTier = <List<int>>[
  <int>[3, 4, 5],
  <int>[6, 8, 10],
  <int>[10, 12, 15],
];

/// rows x cols for a given pair count (always exactly 2 * pairs cells).
const Map<int, List<int>> _gridFor = <int, List<int>>{
  3: <int>[2, 3],
  4: <int>[2, 4],
  5: <int>[2, 5],
  6: <int>[3, 4],
  8: <int>[4, 4],
  10: <int>[4, 5],
  12: <int>[4, 6],
  15: <int>[5, 6],
};

const List<int> _maxValByBand = <int>[9, 20, 99];

List<int> _sample(Random rng, int minVal, int maxVal, int n) {
  final Set<int> picked = <int>{};
  while (picked.length < n) {
    picked.add(minVal + rng.nextInt(maxVal - minVal + 1));
  }
  final List<int> list = picked.toList()..shuffle(rng);
  return list;
}

/// Builds a deterministic, unique, always-solvable level.
/// Same (mode, index) -> same level on every device, forever.
Level buildLevel(GameMode mode, int index) {
  final int band = index ~/ 10; // 0 easy (3-5), 1 medium (6-8), 2 hard (9-12)
  final int within = index % 10;
  final int tier = min(2, within * 3 ~/ 10);
  final Random rng = Random(mode.index * 100003 + index * 1009 + 7);

  switch (mode) {
    case GameMode.pairs:
      final int p = _pairsByTier[band][tier];
      final List<int> dims = _gridFor[p]!;
      final List<int> values = _sample(rng, 1, _maxValByBand[band], p);
      final List<CardItem> cards = <CardItem>[];
      for (int i = 0; i < p; i++) {
        cards.add(CardItem('${values[i]}', i));
        cards.add(CardItem('${values[i]}', i));
      }
      cards.shuffle(rng);
      return Level(mode: mode, index: index, rows: dims[0], cols: dims[1], cards: cards, par3: p, par2: p * 2);

    case GameMode.eqMatch:
      final int p = _pairsByTier[band][tier];
      final List<int> dims = _gridFor[p]!;
      final List<String> ops = band == 0
          ? <String>['+']
          : band == 1
              ? <String>['+', '-']
              : <String>['+', '-', '×'];
      final Set<int> usedAnswers = <int>{};
      final List<CardItem> cards = <CardItem>[];
      for (int i = 0; i < p; i++) {
        int a = 0;
        int b = 0;
        int ans = 0;
        String op = '+';
        // Re-roll until the answer is unique in this level (no ambiguous matches).
        while (true) {
          op = ops[rng.nextInt(ops.length)];
          if (op == '+') {
            a = 1 + rng.nextInt(band == 0 ? 8 : (band == 1 ? 18 : 44));
            b = 1 + rng.nextInt(band == 0 ? 8 : (band == 1 ? 18 : 44));
            ans = a + b;
          } else if (op == '-') {
            a = 2 + rng.nextInt(band == 1 ? 18 : 48);
            b = 1 + rng.nextInt(a - 1);
            ans = a - b;
          } else {
            a = 2 + rng.nextInt(8);
            b = 2 + rng.nextInt(8);
            ans = a * b;
          }
          if (!usedAnswers.contains(ans)) {
            usedAnswers.add(ans);
            break;
          }
        }
        cards.add(CardItem('$a $op $b', i));
        cards.add(CardItem('$ans', i));
      }
      cards.shuffle(rng);
      return Level(mode: mode, index: index, rows: dims[0], cols: dims[1], cards: cards, par3: p, par2: p * 2);

    case GameMode.sequence:
      final int len = min(10, 3 + band * 2 + within ~/ 3);
      final List<int> seq = <int>[];
      int prev = -1;
      for (int i = 0; i < len; i++) {
        int t = rng.nextInt(9);
        while (t == prev) {
          t = rng.nextInt(9);
        }
        seq.add(t);
        prev = t;
      }
      return Level(mode: mode, index: index, sequence: seq, tileCount: 9, par3: 0, par2: 2);

    case GameMode.hidden:
      final int n = <int>[6, 9, 12][band];
      final List<int> dims = n == 6
          ? <int>[2, 3]
          : n == 9
              ? <int>[3, 3]
              : <int>[3, 4];
      final List<int> numbers = _sample(rng, 1, _maxValByBand[band], n);
      final int k = band + 1;
      final List<int> shuffled = List<int>.of(numbers)..shuffle(rng);
      final List<int> targets = shuffled.take(k).toList();
      final int previewMs = max(1500, 4200 - band * 800 - within * 150);
      return Level(
        mode: mode,
        index: index,
        rows: dims[0],
        cols: dims[1],
        numbers: numbers,
        targets: targets,
        previewMs: previewMs,
        par3: band == 0 ? 1 : 0,
        par2: 3,
      );

    case GameMode.targetSum:
      final int p = _pairsByTier[band][tier];
      final List<int> dims = _gridFor[p]!;
      // Target chosen so that enough disjoint (a, T - a) pairs always exist.
      final int target = band == 0
          ? (p >= 5 ? 12 : 10)
          : band == 1
              ? (p >= 10 ? 24 : 20)
              : (p >= 15 ? 32 : 30);
      final Set<int> used = <int>{};
      final List<CardItem> cards = <CardItem>[];
      for (int i = 0; i < p; i++) {
        int a = 1 + rng.nextInt(target - 1);
        while (a == target - a || used.contains(a) || used.contains(target - a)) {
          a = 1 + rng.nextInt(target - 1);
        }
        used.add(a);
        used.add(target - a);
        cards.add(CardItem('$a', i));
        cards.add(CardItem('${target - a}', i));
      }
      cards.shuffle(rng);
      return Level(mode: mode, index: index, rows: dims[0], cols: dims[1], cards: cards, target: target, par3: p, par2: p * 2);

    case GameMode.order:
      final int n = <int>[4, 6, 8][band];
      final List<int> dims = n == 4
          ? <int>[2, 2]
          : n == 6
              ? <int>[2, 3]
              : <int>[2, 4];
      final List<int> numbers = _sample(rng, 1, _maxValByBand[band], n);
      final int previewMs = max(1500, 4000 - band * 700 - within * 120);
      return Level(
        mode: mode,
        index: index,
        rows: dims[0],
        cols: dims[1],
        numbers: numbers,
        previewMs: previewMs,
        par3: band == 0 ? 1 : 0,
        par2: 3,
      );

    case GameMode.builder:
      final List<String> ops = band == 0
          ? <String>['+']
          : band == 1
              ? <String>['+', '-']
              : <String>['×'];
      final String op = ops[rng.nextInt(ops.length)];
      int a = 0;
      int b = 0;
      int c = 0;
      if (op == '+') {
        a = 2 + rng.nextInt(band == 0 ? 7 : 14);
        b = 2 + rng.nextInt(band == 0 ? 7 : 14);
        c = a + b;
      } else if (op == '-') {
        a = 5 + rng.nextInt(14);
        b = 1 + rng.nextInt(a - 1);
        c = a - b;
      } else {
        a = 3 + rng.nextInt(7);
        b = 3 + rng.nextInt(7);
        c = a * b;
      }
      final List<CardItem> cards = <CardItem>[
        CardItem('$a', 0),
        CardItem(op, 1),
        CardItem('$b', 2),
        CardItem('$c', 3),
      ]..shuffle(rng);
      final int previewMs = max(1500, 3800 - band * 700 - within * 120);
      return Level(
        mode: mode,
        index: index,
        rows: 2,
        cols: 2,
        cards: cards,
        previewMs: previewMs,
        par3: band == 0 ? 1 : 0,
        par2: 3,
      );
  }
}

/// Today's daily challenge (deterministic worldwide): [modeIndex, levelIndex].
List<int> dailyLevelFor(DateTime now) {
  final int doy = now.difference(DateTime(now.year, 1, 1)).inDays;
  return <int>[doy % kModes.length, (doy ~/ kModes.length) % 30];
}

/// Kid-friendly 3-step guide for a mode (big emoji + tiny localized text).
class GuideStep {
  const GuideStep(this.emoji, this.textKey);

  final String emoji;
  final String textKey;
}

const Map<GameMode, List<GuideStep>> kGuides = <GameMode, List<GuideStep>>{
  GameMode.pairs: <GuideStep>[GuideStep('👆', 'g_pairs_1'), GuideStep('🧠', 'g_pairs_2'), GuideStep('🪐', 'g_pairs_3')],
  GameMode.eqMatch: <GuideStep>[GuideStep('👆', 'g_eqmatch_1'), GuideStep('➕', 'g_eqmatch_2'), GuideStep('🎯', 'g_eqmatch_3')],
  GameMode.sequence: <GuideStep>[GuideStep('👀', 'g_sequence_1'), GuideStep('🧠', 'g_sequence_2'), GuideStep('🚀', 'g_sequence_3')],
  GameMode.hidden: <GuideStep>[GuideStep('👀', 'g_hidden_1'), GuideStep('🙈', 'g_hidden_2'), GuideStep('🔍', 'g_hidden_3')],
  GameMode.targetSum: <GuideStep>[GuideStep('🎯', 'g_target_1'), GuideStep('👆', 'g_target_2'), GuideStep('➕', 'g_target_3')],
  GameMode.order: <GuideStep>[GuideStep('🧠', 'g_order_1'), GuideStep('🙈', 'g_order_2'), GuideStep('📈', 'g_order_3')],
  GameMode.builder: <GuideStep>[GuideStep('👀', 'g_builder_1'), GuideStep('🧠', 'g_builder_2'), GuideStep('🧩', 'g_builder_3')],
};
