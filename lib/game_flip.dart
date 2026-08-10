import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'sfx.dart';
import 'strings.dart';
import 'widgets.dart';

/// Flip-and-match engine used by Number Pairs, Equation Match and Target Sum.
class FlipMatchGame extends StatefulWidget {
  const FlipMatchGame({super.key, required this.level, required this.onWin});

  final Level level;
  final WinCallback onWin;

  @override
  State<FlipMatchGame> createState() => _FlipMatchGameState();
}

class _FlipMatchGameState extends State<FlipMatchGame> {
  late final List<bool> _faceUp = List<bool>.filled(widget.level.cards.length, false);
  late final List<bool> _matched = List<bool>.filled(widget.level.cards.length, false);
  int? _first;
  int _mistakes = 0;
  int _moves = 0;
  bool _busy = false;

  void _tap(int i) {
    if (_busy || _matched[i] || _faceUp[i]) {
      return;
    }
    Sfx.play('flip');
    setState(() => _faceUp[i] = true);
    if (_first == null) {
      _first = i;
      return;
    }
    final int first = _first!;
    _first = null;
    _moves++;
    if (widget.level.cards[first].pairId == widget.level.cards[i].pairId) {
      Sfx.play('match');
      setState(() {
        _matched[first] = true;
        _matched[i] = true;
      });
      if (_matched.every((bool m) => m)) {
        Future<void>.delayed(const Duration(milliseconds: 550), () {
          if (!mounted) {
            return;
          }
          widget.onWin(_mistakes, _moves);
        });
      }
    } else {
      _busy = true;
      _mistakes++;
      Sfx.play('wrong');
      Future<void>.delayed(const Duration(milliseconds: 750), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _faceUp[first] = false;
          _faceUp[i] = false;
          _busy = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Level level = widget.level;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: <Widget>[
              if (level.target > 0) ChipPill(emoji: '🎯', text: '${S.t('target')}: ${level.target}'),
              ChipPill(emoji: '❌', text: '${S.t('mistakes')}: $_mistakes'),
              ChipPill(emoji: '👆', text: '${S.t('moves')}: $_moves'),
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
                          faceUp: _faceUp[i] || _matched[i],
                          matched: _matched[i],
                          label: level.cards[i].label,
                          accent: Color(kModes[level.mode.index].color),
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
