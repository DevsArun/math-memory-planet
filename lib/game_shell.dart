import 'dart:async';

import 'package:flutter/material.dart';

import 'game_builder.dart';
import 'game_flip.dart';
import 'game_hidden.dart';
import 'game_order.dart';
import 'game_sequence.dart';
import 'models.dart';
import 'sfx.dart';
import 'state.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Grid of 30 levels for one mode (planet).
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key, required this.modeIndex});

  final int modeIndex;

  @override
  Widget build(BuildContext context) {
    final ModeInfo mode = kModes[modeIndex];
    return GradientScaffold(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(mode.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    S.t(mode.titleKey),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ChipPill(emoji: '⭐', text: '${appState.starsForMode(modeIndex)}/90'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                S.t(mode.hintKey),
                style: TextStyle(fontSize: 16, color: AppColors.white.withValues(alpha: 0.85)),
              ),
            ),
          ),
          Expanded(
            child: GridView(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                childAspectRatio: 0.92,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              children: <Widget>[
                for (int level = 0; level < 30; level++)
                  _LevelCell(modeIndex: modeIndex, level: level, color: Color(mode.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCell extends StatelessWidget {
  const _LevelCell({required this.modeIndex, required this.level, required this.color});

  final int modeIndex;
  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = appState.levelUnlocked(modeIndex, level);
    final int stars = appState.starsFor(modeIndex, level);
    return ChunkyButton(
      color: unlocked ? AppColors.cardFace : AppColors.white.withValues(alpha: 0.14),
      minHeight: 0,
      padding: const EdgeInsets.all(8),
      radius: 20,
      onTap: () {
        if (unlocked) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => GameScreen(modeIndex: modeIndex, levelIndex: level)),
          );
        } else {
          Sfx.play('wrong');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (unlocked)
            Text(
              '${level + 1}',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color),
            )
          else
            Icon(Icons.lock_rounded, color: AppColors.white.withValues(alpha: 0.5), size: 26),
          const SizedBox(height: 4),
          StarBar(stars: stars, size: 16),
        ],
      ),
    );
  }
}

/// Hosts one level: header + the mode-specific game widget + win flow.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.modeIndex, required this.levelIndex});

  final int modeIndex;
  final int levelIndex;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _replayCount = 0;
  late DateTime _start;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
  }

  Level get _level => buildLevel(kModes[widget.modeIndex].mode, widget.levelIndex);

  void _onWin(int mistakes, int moves) {
    if (_won) {
      return;
    }
    _won = true;
    final int seconds = DateTime.now().difference(_start).inSeconds;
    final Level level = _level;
    final int stars = mistakes <= level.par3 ? 3 : (mistakes <= level.par2 ? 2 : 1);
    appState.completeLevel(
      widget.modeIndex,
      widget.levelIndex,
      stars,
      mistakes: mistakes,
      moves: moves,
      seconds: seconds,
    );
    Sfx.play('win');
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      _showWin(stars);
    });
  }

  void _showWin(int stars) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => WinDialog(
        stars: stars,
        hasNext: widget.levelIndex < 29,
        onNext: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => GameScreen(modeIndex: widget.modeIndex, levelIndex: widget.levelIndex + 1),
            ),
          );
        },
        onReplay: () {
          Navigator.of(dialogContext).pop();
          _replay();
        },
        onHome: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _replay() {
    setState(() {
      _won = false;
      _start = DateTime.now();
      _replayCount++;
    });
  }

  Widget _buildGame(ModeInfo mode, Level level) {
    switch (mode.mode) {
      case GameMode.pairs:
      case GameMode.eqMatch:
      case GameMode.targetSum:
        return FlipMatchGame(level: level, onWin: _onWin);
      case GameMode.sequence:
        return SequenceGame(level: level, onWin: _onWin);
      case GameMode.hidden:
        return HiddenGame(level: level, onWin: _onWin);
      case GameMode.order:
        return OrderGame(level: level, onWin: _onWin);
      case GameMode.builder:
        return BuilderGame(level: level, onWin: _onWin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ModeInfo mode = kModes[widget.modeIndex];
    final Level level = _level;
    return GradientScaffold(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 0),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(mode.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${S.t('level')} ${widget.levelIndex + 1}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.white, size: 30),
                  onPressed: _replay,
                ),
              ],
            ),
          ),
          Expanded(
            child: KeyedSubtree(
              key: ValueKey<int>(_replayCount),
              child: _buildGame(mode, level),
            ),
          ),
        ],
      ),
    );
  }
}

/// Celebration dialog with animated stars and confetti.
class WinDialog extends StatefulWidget {
  const WinDialog({
    super.key,
    required this.stars,
    required this.hasNext,
    required this.onNext,
    required this.onReplay,
    required this.onHome,
  });

  final int stars;
  final bool hasNext;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  @override
  State<WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends State<WinDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const Positioned.fill(child: ConfettiOverlay()),
          Container(
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardFace,
              borderRadius: BorderRadius.circular(28),
              boxShadow: <BoxShadow>[
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  S.t('wellDone'),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (int i = 0; i < 3; i++)
                      _AnimatedStar(filled: i < widget.stars, delay: 0.12 * i + 0.1, animation: _pop),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _WinButton(emoji: '🏠', label: S.t('home'), color: AppColors.sky, onTap: widget.onHome),
                    const SizedBox(width: 10),
                    _WinButton(emoji: '🔁', label: S.t('replay'), color: AppColors.coral, onTap: widget.onReplay),
                    if (widget.hasNext) ...<Widget>[
                      const SizedBox(width: 10),
                      _WinButton(emoji: '▶️', label: S.t('next'), color: AppColors.mint, onTap: widget.onNext),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStar extends StatelessWidget {
  const _AnimatedStar({required this.filled, required this.delay, required this.animation});

  final bool filled;
  final double delay;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final Animation<double> scale = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, delay + 0.55, curve: Curves.elasticOut),
    );
    return ScaleTransition(
      scale: scale,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          Icons.star_rounded,
          size: 54,
          color: filled ? AppColors.sunYellow : AppColors.textDark.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

class _WinButton extends StatelessWidget {
  const _WinButton({required this.emoji, required this.label, required this.color, required this.onTap});

  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      color: color,
      minHeight: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}
