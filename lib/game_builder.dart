import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'sfx.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Equation is shown briefly, then cards flip. Rebuild it in order:
/// number -> operator -> number -> answer.
class BuilderGame extends StatefulWidget {
  const BuilderGame({super.key, required this.level, required this.onWin});

  final Level level;
  final WinCallback onWin;

  @override
  State<BuilderGame> createState() => _BuilderGameState();
}

class _BuilderGameState extends State<BuilderGame> {
  late final List<bool> _used = List<bool>.filled(widget.level.cards.length, false);
  bool _preview = true;
  int _step = 0;
  int _mistakes = 0;
  int _wrongIdx = -1;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.level.previewMs), () {
      if (!mounted) {
        return;
      }
      setState(() => _preview = false);
    });
  }

  String _labelFor(int pairId) {
    return widget.level.cards.firstWhere((CardItem c) => c.pairId == pairId).label;
  }

  void _tap(int i) {
    if (_preview || _used[i]) {
      return;
    }
    if (widget.level.cards[i].pairId == _step) {
      Sfx.play('tap');
      setState(() {
        _used[i] = true;
        _step++;
      });
      if (_step >= 4) {
        Sfx.play('match');
        Future<void>.delayed(const Duration(milliseconds: 450), () {
          if (!mounted) {
            return;
          }
          widget.onWin(_mistakes, 0);
        });
      }
    } else {
      _mistakes++;
      Sfx.play('wrong');
      HapticFeedback.lightImpact();
      setState(() => _wrongIdx = i);
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) {
          return;
        }
        setState(() => _wrongIdx = -1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Level level = widget.level;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: <Widget>[
              ChipPill(emoji: _preview ? '👀' : '🧩', text: _preview ? S.t('watch') : S.t('yourTurn')),
              ChipPill(emoji: '❌', text: '${S.t('mistakes')}: $_mistakes'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int k = 0; k < 4; k++)
                Container(
                  width: 72,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: k < _step ? AppColors.mint.withValues(alpha: 0.25) : AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: k < _step ? AppColors.mint : AppColors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          k < _step ? _labelFor(k) : '?',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.white),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double cardW = (c.maxWidth - 24 - (level.cols - 1) * 10) / level.cols;
              final double cardH = (c.maxHeight - 16 - (level.rows - 1) * 10) / level.rows;
              final double size = cardW < cardH ? cardW : cardH;
              return Center(
                child: SizedBox(
                  width: size * level.cols + (level.cols - 1) * 10,
                  height: size * level.rows + (level.rows - 1) * 10,
                  child: GridView.count(
                    crossAxisCount: level.cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      for (int i = 0; i < level.cards.length; i++)
                        FlipCard(
                          faceUp: _preview || _used[i],
                          matched: _used[i],
                          label: level.cards[i].label,
                          accent: _wrongIdx == i ? AppColors.coral : Color(kModes[level.mode.index].color),
                          onTap: () => _tap(i),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
