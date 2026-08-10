import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sfx.dart';
import 'state.dart';
import 'theme.dart';

/// Gradient background scaffold themed by the selected reward theme.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final List<int> t = AppState.themes[appState.theme];
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(t[0]), Color(t[1])],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

/// Big chunky kid-friendly button with spring press, haptic and sound.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.onTap,
    required this.child,
    this.color = AppColors.sunYellow,
    this.radius = 24,
    this.minHeight = 72,
    this.padding,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color color;
  final double radius;
  final double minHeight;
  final EdgeInsets? padding;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  void _setDown(bool value) {
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _setDown(true);
      },
      onTapUp: (_) {
        _setDown(false);
        Sfx.play('button');
        widget.onTap();
      },
      onTapCancel: () => _setDown(false),
      child: AnimatedScale(
        scale: _down ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(widthFactor: 1, child: widget.child),
        ),
      ),
    );
  }
}

/// Small rounded info chip: emoji + text.
class ChipPill extends StatelessWidget {
  const ChipPill({super.key, required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.white),
      ),
    );
  }
}

/// Row of stars (filled / outline).
class StarBar extends StatelessWidget {
  const StarBar({super.key, required this.stars, this.total = 3, this.size = 24});

  final int stars;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            color: i < stars ? AppColors.sunYellow : AppColors.white.withValues(alpha: 0.35),
            size: size,
          ),
      ],
    );
  }
}

/// A memory card with a 3D flip animation.
class FlipCard extends StatelessWidget {
  const FlipCard({
    super.key,
    required this.faceUp,
    required this.label,
    required this.accent,
    required this.onTap,
    this.matched = false,
  });

  final bool faceUp;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: faceUp ? 0 : math.pi, end: faceUp ? 0 : math.pi),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        builder: (BuildContext context, double angle, Widget? child) {
          final bool showFront = angle <= math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFront
                ? _CardFace(label: label, accent: accent, matched: matched)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: const _CardBack(),
                  ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.label, required this.accent, required this.matched});

  final String label;
  final Color accent;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFace,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: matched ? AppColors.mint : accent, width: matched ? 4 : 3),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.textDark),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    final List<int> g = AppState.cardBacks[appState.cardBack];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(g[0]), Color(g[1])],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(AppState.cardBackEmojis[appState.cardBack], style: const TextStyle(fontSize: 34)),
      ),
    );
  }
}

/// One-shot confetti burst (3 selectable styles). No plugin needed.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _Particle {
  const _Particle(this.x, this.delay, this.speed, this.size, this.color, this.wobble, this.shape);

  final double x;
  final double delay;
  final double speed;
  final double size;
  final int color;
  final double wobble;
  final int shape;
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  late final List<_Particle> _particles = _makeParticles();

  static List<_Particle> _makeParticles() {
    final math.Random rng = math.Random(7);
    const List<int> colors = <int>[0xFFFFD233, 0xFFFF6B6B, 0xFF4ECDC4, 0xFF45B7FF, 0xFFFF8ED4, 0xFF7ED957];
    return List<_Particle>.generate(
      90,
      (int i) => _Particle(
        rng.nextDouble(),
        rng.nextDouble() * 0.35,
        0.55 + rng.nextDouble() * 0.75,
        5 + rng.nextDouble() * 8,
        colors[i % colors.length],
        rng.nextDouble() * 6.28,
        i % 3,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: _ConfettiPainter(_particles, _controller.value, appState.confetti),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress, this.variant);

  final List<_Particle> particles;
  final double progress;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (final _Particle p in particles) {
      final double t = progress * 1.5 - p.delay;
      if (t <= 0) {
        continue;
      }
      final double tt = t > 1 ? 1 : t;
      final double y = -20 + tt * (size.height + 60) * p.speed;
      final double x = p.x * size.width + math.sin(tt * 6 + p.wobble) * 26;
      paint.color = Color(p.color).withValues(alpha: 1 - tt * 0.85);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(tt * 5 + p.wobble);
      if (variant == 1) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else if (variant == 2) {
        canvas.drawPath(_star(p.size), paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), paint);
      }
      canvas.restore();
    }
  }

  static Path _star(double r) {
    final Path path = Path();
    for (int i = 0; i < 8; i++) {
      final double ang = math.pi / 4 * i - math.pi / 2;
      final double rad = i.isEven ? r : r * 0.45;
      final double x = rad * math.cos(ang);
      final double y = rad * math.sin(ang);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
