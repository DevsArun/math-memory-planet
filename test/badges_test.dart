import 'package:flutter_test/flutter_test.dart';
import 'package:mathmemoryplanet/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('badges unlock as progress accumulates', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await appState.load();
    expect(appState.badges.isEmpty, isTrue);

    List<String> fresh = appState.completeLevel(0, 0, 3, mistakes: 0, moves: 6, seconds: 30);
    expect(fresh.contains('first_win'), isTrue);
    expect(fresh.contains('perfect'), isTrue);

    for (int i = 1; i < 10; i++) {
      fresh = appState.completeLevel(0, i, 2, mistakes: 1);
    }
    expect(appState.levelsCompleted, 10);
    expect(appState.badges.contains('ten_levels'), isTrue);

    // Unlocking is one-shot: replaying a level must not re-award.
    fresh = appState.completeLevel(0, 0, 3, mistakes: 0);
    expect(fresh.contains('first_win'), isFalse);
  });
}
