import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Tiny fire-and-forget sound player. All sounds are short bundled wav files.
class Sfx {
  Sfx._();

  static bool enabled = true;

  static void play(String name) {
    if (!enabled) {
      return;
    }
    unawaited(_play(name));
  }

  static Future<void> _play(String name) async {
    try {
      final AudioPlayer player = AudioPlayer();
      unawaited(player.onPlayerComplete.first.then((_) => player.dispose()));
      await player.play(AssetSource('audio/$name.wav'));
    } catch (_) {
      // Audio unavailable (e.g. unit tests) - silently ignore.
    }
  }
}
