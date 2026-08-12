import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Shown in the About dialog. Keep in sync with pubspec.yaml version.
const String kAppVersion = '1.4.5+12';

/// A collectible trophy badge.
class BadgeDef {
  const BadgeDef(this.key, this.emoji, this.nameKey);

  final String key;
  final String emoji;
  final String nameKey;
}

/// Global app state: progress, stars, streak, badges, cosmetics, settings, stats.
/// Persisted locally with shared_preferences only. Nothing ever leaves the device.
class AppState extends ChangeNotifier {
  static const List<List<int>> cardBacks = <List<int>>[
    <int>[0xFF6C4FD8, 0xFF8E6FF0],
    <int>[0xFF45B7FF, 0xFF7ED3FF],
    <int>[0xFFFF6B6B, 0xFFFF9E7A],
    <int>[0xFF4ECDC4, 0xFF7EE8D9],
    <int>[0xFFFF8ED4, 0xFFFFB3E2],
    <int>[0xFF7ED957, 0xFFA8E88A],
  ];
  static const List<String> cardBackEmojis = <String>['🪐', '🚀', '⭐', '👾', '🌙', '☄️'];
  static const List<int> cardBackCost = <int>[0, 15, 30, 50, 80, 120];

  static const List<List<int>> themes = <List<int>>[
    <int>[0xFFFDF6EC, 0xFFDCEFFF],
    <int>[0xFFFFF0F6, 0xFFFFD9EC],
    <int>[0xFFEFFFF9, 0xFFD3F5FF],
    <int>[0xFFFFFBE6, 0xFFE7F9D4],
  ];
  static const List<int> themeCost = <int>[0, 40, 90, 150];

  static const List<String> confettiEmojis = <String>['🎊', '⚪', '⭐'];
  static const List<int> confettiCost = <int>[0, 60, 100];

  static const List<BadgeDef> badgeDefs = <BadgeDef>[
    BadgeDef('first_win', '🏅', 'b_first_win'),
    BadgeDef('ten_levels', '🌟', 'b_ten_levels'),
    BadgeDef('perfect', '💯', 'b_perfect'),
    BadgeDef('all_planets', '🪐', 'b_all_planets'),
    BadgeDef('streak_7', '🔥', 'b_streak_7'),
    BadgeDef('stars_100', '⭐', 'b_stars_100'),
    BadgeDef('planet_master', '👑', 'b_planet_master'),
    BadgeDef('daily_comet', '☄️', 'b_daily'),
  ];

  static BadgeDef badgeDef(String key) =>
      badgeDefs.firstWhere((BadgeDef d) => d.key == key);

  late SharedPreferences _p;

  bool muted = false;
  String locale = 'en';
  int cardBack = 0;
  int theme = 0;
  int confetti = 0;
  int streak = 0;
  String lastDay = '';
  int gamesPlayed = 0;
  int totalMoves = 0;
  int totalMistakes = 0;
  int totalSeconds = 0;
  String childName = '';
  bool onboardingDone = false;

  final Map<String, int> stars = <String, int>{};
  final Map<int, int> modePlays = <int, int>{};
  final Set<String> badges = <String>{};
  final Set<String> guidesSeen = <String>{};

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    muted = _p.getBool('muted') ?? false;
    locale = _p.getString('locale') ?? 'en';
    cardBack = _p.getInt('cardBack') ?? 0;
    theme = _p.getInt('theme') ?? 0;
    confetti = _p.getInt('confetti') ?? 0;
    streak = _p.getInt('streak') ?? 0;
    lastDay = _p.getString('lastDay') ?? '';
    gamesPlayed = _p.getInt('gamesPlayed') ?? 0;
    totalMoves = _p.getInt('totalMoves') ?? 0;
    totalMistakes = _p.getInt('totalMistakes') ?? 0;
    totalSeconds = _p.getInt('totalSeconds') ?? 0;
    childName = _p.getString('childName') ?? '';
    onboardingDone = _p.getBool('onboardingDone') ?? false;
    badges.addAll(_p.getStringList('badges') ?? <String>[]);
    guidesSeen.addAll(_p.getStringList('guidesSeen') ?? <String>[]);
    for (final String key in _p.getKeys()) {
      if (key.startsWith('s_')) {
        stars[key.substring(2)] = _p.getInt(key) ?? 0;
      } else if (key.startsWith('mp_')) {
        final int? mode = int.tryParse(key.substring(3));
        if (mode != null) {
          modePlays[mode] = _p.getInt(key) ?? 0;
        }
      }
    }
  }

  int get totalStars => stars.values.fold<int>(0, (int a, int b) => a + b);

  int get levelsCompleted => stars.values.where((int s) => s > 0).length;

  int starsFor(int mode, int level) => stars['$mode-$level'] ?? 0;

  int starsForMode(int mode) {
    int sum = 0;
    for (int level = 0; level < 30; level++) {
      sum += starsFor(mode, level);
    }
    return sum;
  }

  bool levelUnlocked(int mode, int level) =>
      level == 0 || starsFor(mode, level - 1) > 0;

  /// Records a completed level. Returns newly unlocked badge keys.
  List<String> completeLevel(
    int mode,
    int level,
    int starCount, {
    int mistakes = 0,
    int moves = 0,
    int seconds = 0,
  }) {
    final String key = '$mode-$level';
    if (starCount > (stars[key] ?? 0)) {
      stars[key] = starCount;
    }
    gamesPlayed++;
    totalMoves += moves;
    totalMistakes += mistakes;
    totalSeconds += seconds;
    modePlays[mode] = (modePlays[mode] ?? 0) + 1;
    _tickStreak();
    final List<String> fresh = _evalBadges(mode, level, mistakes);
    badges.addAll(fresh);
    _save();
    notifyListeners();
    return fresh;
  }

  List<String> _evalBadges(int mode, int level, int mistakes) {
    final List<String> fresh = <String>[];
    void give(String k) {
      if (!badges.contains(k)) {
        fresh.add(k);
      }
    }

    if (levelsCompleted >= 1) {
      give('first_win');
    }
    if (levelsCompleted >= 10) {
      give('ten_levels');
    }
    if (mistakes == 0) {
      give('perfect');
    }
    if (modePlays.length >= kModes.length) {
      give('all_planets');
    }
    if (streak >= 7) {
      give('streak_7');
    }
    if (totalStars >= 100) {
      give('stars_100');
    }
    if (starsForMode(mode) >= 90) {
      give('planet_master');
    }
    final List<int> d = dailyLevelFor(DateTime.now());
    if (mode == d[0] && level == d[1]) {
      give('daily_comet');
    }
    return fresh;
  }

  void _tickStreak() {
    final DateTime now = DateTime.now();
    final String today = _day(now);
    if (lastDay == today) {
      return;
    }
    final String yesterday = _day(now.subtract(const Duration(days: 1)));
    streak = lastDay == yesterday ? streak + 1 : 1;
    lastDay = today;
  }

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool guideSeen(int mode) => guidesSeen.contains('$mode');

  void markGuideSeen(int mode) {
    guidesSeen.add('$mode');
    _p.setStringList('guidesSeen', guidesSeen.toList());
  }

  void completeOnboarding(String name) {
    childName = name.trim();
    onboardingDone = true;
    _p.setString('childName', childName);
    _p.setBool('onboardingDone', true);
    notifyListeners();
  }

  void setMuted(bool value) {
    muted = value;
    _p.setBool('muted', value);
    notifyListeners();
  }

  void setLocale(String code) {
    locale = code;
    _p.setString('locale', code);
    notifyListeners();
  }

  void selectCardBack(int index) {
    cardBack = index;
    _p.setInt('cardBack', index);
    notifyListeners();
  }

  void selectTheme(int index) {
    theme = index;
    _p.setInt('theme', index);
    notifyListeners();
  }

  void selectConfetti(int index) {
    confetti = index;
    _p.setInt('confetti', index);
    notifyListeners();
  }

  void resetAll() {
    stars.clear();
    modePlays.clear();
    badges.clear();
    guidesSeen.clear();
    streak = 0;
    lastDay = '';
    gamesPlayed = 0;
    totalMoves = 0;
    totalMistakes = 0;
    totalSeconds = 0;
    cardBack = 0;
    theme = 0;
    confetti = 0;
    for (final String key in _p.getKeys().toList()) {
      if (key != 'muted' && key != 'locale' && key != 'childName' && key != 'onboardingDone') {
        _p.remove(key);
      }
    }
    _save();
    notifyListeners();
  }

  void _save() {
    _p.setInt('cardBack', cardBack);
    _p.setInt('theme', theme);
    _p.setInt('confetti', confetti);
    _p.setInt('streak', streak);
    _p.setString('lastDay', lastDay);
    _p.setInt('gamesPlayed', gamesPlayed);
    _p.setInt('totalMoves', totalMoves);
    _p.setInt('totalMistakes', totalMistakes);
    _p.setInt('totalSeconds', totalSeconds);
    _p.setStringList('badges', badges.toList());
    stars.forEach((String key, int value) {
      _p.setInt('s_$key', value);
    });
    modePlays.forEach((int key, int value) {
      _p.setInt('mp_$key', value);
    });
  }
}

final AppState appState = AppState();
