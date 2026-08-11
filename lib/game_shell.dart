import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Winding galaxy-path level map (Candy-Crush style), TOP -> BOTTOM:
/// level 1 at the top, level 30 at the bottom. Auto-scrolls to current level.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key, required this.modeIndex});

  final int modeIndex;

  static const double spacing = 112;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final ScrollController _sc = ScrollController();
  late final int _current = _computeCurrent();

  int _computeCurrent() {
    int c = 0;
    while (c < 29 && appState.starsFor(widget.modeIndex, c) > 0) {
      c++;
    }
    return c;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sc.hasClients) {
        return;
      }
      final double target = 90 + _current * LevelSelectScreen.spacing - 220;
      final double maxScroll = _sc.position.maxScrollExtent;
      _sc.jumpTo(math.max(0, math.min(target, maxScroll)));
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ModeInfo mode = kModes[widget.modeIndex];
    return GradientScaffold(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(mode.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    S.t(mode.titleKey),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ChipPill(emoji: '⭐', text: '${appState.starsForMode(widget.modeIndex)}/90'),
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded, color: AppColors.textDark, size: 30),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext dialogContext) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: GuideView(
                            modeIndex: widget.modeIndex,
                            onDone: () => Navigator.of(dialogContext).pop(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                S.t(mode.hintKey),
                style: TextStyle(fontSize: 16, color: AppColors.textDark.withValues(alpha: 0.85)),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                const double spacing = LevelSelectScreen.spacing;
                final double height = 30 * spacing + 160;
                return SingleChildScrollView(
                  controller: _sc,
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    width: c.maxWidth,
                    height: height,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: CustomPaint(painter: _PathPainter(c.maxWidth, spacing)),
                        ),
                        for (int level = 0; level < 30; level++)
                          _buildNode(context, mode, level, c.maxWidth, spacing),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(BuildContext context, ModeInfo mode, int level, double width, double spacing) {
    final Offset pos = _nodePos(width, spacing, level);
    final bool unlocked = appState.levelUnlocked(widget.modeIndex, level);
    final int stars = appState.starsFor(widget.modeIndex, level);
    return Positioned(
      left: pos.dx - 36,
      top: pos.dy - 45,
      child: _LevelNode(
        number: level + 1,
        stars: stars,
        unlocked: unlocked,
        isCurrent: unlocked && level == _current,
        color: Color(mode.color),
        onTap: () {
          if (unlocked) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GameScreen(modeIndex: widget.modeIndex, levelIndex: level),
              ),
            );
          } else {
            Sfx.play('wrong');
          }
        },
      ),
    );
  }
}

/// Top-down: level 1 near the top, level 30 at the bottom.
Offset _nodePos(double width, double spacing, int i) {
  final double x = width / 2 + math.sin(i * 0.85) * (width * 0.26);
  final double y = 90 + i * spacing;
  return Offset(x, y);
}

class _PathPainter extends CustomPainter {
  const _PathPainter(this.width, this.spacing);

  final double width;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.textDark.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final Path path = Path();
    for (int i = 0; i < 30; i++) {
      final Offset p = _nodePos(width, spacing, i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) => false;
}

class _LevelNode extends StatefulWidget {
  const _LevelNode({
    required this.number,
    required this.stars,
    required this.unlocked,
    required this.isCurrent,
    required this.color,
    required this.onTap,
  });

  final int number;
  final int stars;
  final bool unlocked;
  final bool isCurrent;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<_LevelNode> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isCurrent) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool done = widget.stars > 0;
    final Widget circle = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: !widget.unlocked
            ? AppColors.textDark.withValues(alpha: 0.08)
            : done
                ? widget.color
                : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.unlocked ? widget.color : AppColors.textDark.withValues(alpha: 0.3),
          width: 4,
        ),
        boxShadow: widget.isCurrent
            ? <BoxShadow>[BoxShadow(color: widget.color.withValues(alpha: 0.8), blurRadius: 20)]
            : <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: !widget.unlocked
            ? Icon(Icons.lock_rounded, color: AppColors.textDark.withValues(alpha: 0.55), size: 28)
            : done
                ? const Icon(Icons.check_rounded, color: AppColors.textDark, size: 34)
                : Text(
                    '${widget.number}',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: widget.color),
                  ),
      ),
    );
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.isCurrent)
            AnimatedBuilder(
              animation: _pulse,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(scale: 1 + 0.08 * _pulse.value, child: child);
              },
              child: circle,
            )
          else
            circle,
          const SizedBox(height: 3),
          StarBar(stars: widget.stars, size: 14),
        ],
      ),
    );
  }
}

/// Full kid-friendly "how to play" guide: Nova + 3 big-emoji steps + Play button.
class GuideView extends StatelessWidget {
  const GuideView({super.key, required this.modeIndex, required this.onDone});

  final int modeIndex;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final ModeInfo mode = kModes[modeIndex];
    final List<GuideStep> steps = kGuides[mode.mode] ?? kGuides[GameMode.pairs]!;
    return Container(
      color: Color(AppState.themes[appState.theme][1]),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Mascot(size: 100),
              const SizedBox(height: 8),
              Text(
                S.t('howTo'),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                '${mode.emoji} ${S.t(mode.titleKey)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 18),
              for (int i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardFace,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Color(mode.color).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(steps[i].emoji, style: const TextStyle(fontSize: 30))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            S.t(steps[i].textKey),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ChunkyButton(
                color: AppColors.mint,
                gradient: const LinearGradient(colors: <Color>[Color(0xFF4ECDC4), Color(0xFF45B7FF)]),
                onTap: onDone,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.play_arrow_rounded, color: AppColors.textDark, size: 30),
                    const SizedBox(width: 6),
                    Text(
                      S.t('play'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hosts one level: header + level-start splash + game widget + win flow.
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
  bool _started = false;
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    if (appState.guideSeen(widget.modeIndex)) {
      _armSplash();
    } else {
      _showGuide = true;
    }
  }

  void _armSplash() {
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _started = true;
        _start = DateTime.now();
      });
      Sfx.play('levelstart');
    });
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
    final List<String> fresh = appState.completeLevel(
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
      _showWin(stars, fresh);
    });
  }

  void _showWin(int stars, List<String> fresh) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => WinDialog(
        stars: stars,
        hasNext: widget.levelIndex < 29,
        newBadges: fresh,
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

  void _showGuideDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: GuideView(
            modeIndex: widget.modeIndex,
            onDone: () => Navigator.of(dialogContext).pop(),
          ),
        ),
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
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(mode.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${S.t('level')} ${widget.levelIndex + 1}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded, color: AppColors.textDark, size: 30),
                  onPressed: () => _showGuideDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textDark, size: 30),
                  onPressed: _replay,
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                if (_started)
                  KeyedSubtree(
                    key: ValueKey<int>(_replayCount),
                    child: _buildGame(mode, level),
                  )
                else
                  const SizedBox.shrink(),
                if (_showGuide)
                  Positioned.fill(
                    child: GuideView(
                      modeIndex: widget.modeIndex,
                      onDone: () {
                        appState.markGuideSeen(widget.modeIndex);
                        setState(() => _showGuide = false);
                        _armSplash();
                      },
                    ),
                  ),
                if (!_started)
                  Positioned.fill(
                    child: Container(
                      color: Color(AppState.themes[appState.theme][1]),
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Mascot(size: 110),
                            const SizedBox(height: 14),
                            Text(
                              '${S.t('level')} ${widget.levelIndex + 1}',
                              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Bubble(text: S.t(mode.hintKey)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              S.t('ready'),
                              style: TextStyle(fontSize: 18, color: AppColors.textDark.withValues(alpha: 0.75)),
                            ),
                          ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Celebration dialog: mascot, rotating rays, animated stars, confetti, badges.
class WinDialog extends StatefulWidget {
  const WinDialog({
    super.key,
    required this.stars,
    required this.hasNext,
    required this.newBadges,
    required this.onNext,
    required this.onReplay,
    required this.onHome,
  });

  final int stars;
  final bool hasNext;
  final List<String> newBadges;
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

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void initState() {
    super.initState();
    if (widget.newBadges.isNotEmpty) {
      Sfx.play('trophy');
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _spin.dispose();
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
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _spin,
                builder: (BuildContext context, Widget? child) {
                  return CustomPaint(painter: _RaysPainter(_spin.value), child: const SizedBox.expand());
                },
              ),
            ),
          ),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                const Mascot(size: 92),
                const SizedBox(height: 6),
                Text(
                  S.t('wellDone'),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (int i = 0; i < 3; i++)
                      _AnimatedStar(filled: i < widget.stars, delay: 0.12 * i + 0.1, animation: _pop),
                  ],
                ),
                if (widget.newBadges.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    '🏅 ${S.t('newBadge')}!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.coral),
                  ),
                  for (final String k in widget.newBadges)
                    Text(
                      '${AppState.badgeDef(k).emoji} ${S.t(AppState.badgeDef(k).nameKey)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                ],
                const SizedBox(height: 18),
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
          ),
        ],
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  const _RaysPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppColors.sunYellow.withValues(alpha: 0.10);
    final Offset c = size.center(Offset.zero);
    final double radius = size.width > size.height ? size.width : size.height;
    for (int i = 0; i < 12; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(t * 6.283 + i * 0.5236);
      canvas.drawRect(Rect.fromLTWH(radius * 0.18, -radius * 0.045, radius, radius * 0.09), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) => true;
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
