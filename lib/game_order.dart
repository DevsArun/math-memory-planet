import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'sfx.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Cards shown briefly, then hidden. Tap them from smallest to biggest.
class OrderGame extends StatefulWidget {
  const OrderGame({super.key, required this.level, required this.onWin});

  final Level level;
  final WinCallback onWin;

  @override
  State<OrderGame> createState() => _OrderGameState();
}

class _OrderGameState extends State<OrderGame> {
  late final List<bool> _up = List<bool>.filled(widget.level.numbers.length, false);
  late final List<int> _sorted = List<int>.of(widget.level.numbers)..sort();
  bool _preview = true;
  int _next = 0;
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

  void _peek() {
    if (_preview) {
      return;
    }
    Sfx.play('flip');
    setState(() {
      _preview = true;
      _mistakes++;
    });
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      setState(() => _preview = false);
    });
  }

  void _tap(int i) {
    if (_preview || _up[i]) {
      return;
    }
    if (widget.level.numbers[i] == _sorted[_next]) {
      Sfx.play('star');
      setState(() {
        _up[i] = true;
        _next++;
      });
      if (_next >= _sorted.length) {
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: <Widget>[
              ChipPill(emoji: _preview ? '👀' : '📈', text: _preview ? S.t('watch') : S.t('yourTurn')),
              ChipPill(emoji: '✅', text: '$_next/${_sorted.length}'),
              ChipPill(emoji: '❌', text: '${S.t('mistakes')}: $_mistakes'),
              if (!_preview) GestureDetector(onTap: _peek, child: ChipPill(emoji: '👀', text: S.t('peek'))),
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
                      for (int i = 0; i < level.numbers.length; i++)
                        FlipCard(
                          faceUp: _preview || _up[i],
                          matched: _up[i],
                          label: '${level.numbers[i]}',
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
