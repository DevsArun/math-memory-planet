import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'sfx.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Cards are shown briefly, then hidden. Find the requested numbers.
class HiddenGame extends StatefulWidget {
  const HiddenGame({super.key, required this.level, required this.onWin});

  final Level level;
  final WinCallback onWin;

  @override
  State<HiddenGame> createState() => _HiddenGameState();
}

class _HiddenGameState extends State<HiddenGame> {
  late final List<bool> _found = List<bool>.filled(widget.level.numbers.length, false);
  bool _preview = true;
  int _targetIndex = 0;
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

  void _tap(int i) {
    if (_preview || _found[i]) {
      return;
    }
    final List<int> targets = widget.level.targets;
    if (_targetIndex < targets.length && widget.level.numbers[i] == targets[_targetIndex]) {
      Sfx.play('star');
      setState(() {
        _found[i] = true;
        _targetIndex++;
      });
      if (_targetIndex >= targets.length) {
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
    final bool done = _targetIndex >= level.targets.length;
    final int shownTarget = level.targets[math.min(_targetIndex, level.targets.length - 1)];
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: <Widget>[
              if (_preview)
                ChipPill(emoji: '👀', text: S.t('watch'))
              else if (!done)
                ChipPill(emoji: '🔍', text: '${S.t('find')} $shownTarget'),
              ChipPill(emoji: '❌', text: '${S.t('mistakes')}: $_mistakes'),
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
                          faceUp: _preview || _found[i],
                          matched: _found[i],
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
