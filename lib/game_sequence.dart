import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'sfx.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Simon-style sequence memory on a 3x3 planet grid.
class SequenceGame extends StatefulWidget {
  const SequenceGame({super.key, required this.level, required this.onWin});

  final Level level;
  final WinCallback onWin;

  @override
  State<SequenceGame> createState() => _SequenceGameState();
}

class _SequenceGameState extends State<SequenceGame> {
  static const List<String> _tileEmojis = <String>['🪐', '🌙', '⭐', '☄️', '🚀', '👾', '🌍', '🛸', '☀️'];

  int _flash = -1;
  int _inputIndex = 0;
  int _mistakes = 0;
  bool _inputEnabled = false;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _showSequence();
  }

  Future<void> _showSequence() async {
    final int token = ++_run;
    setState(() {
      _inputEnabled = false;
      _inputIndex = 0;
      _flash = -1;
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted || token != _run) {
      return;
    }
    for (final int t in widget.level.sequence) {
      if (!mounted || token != _run) {
        return;
      }
      setState(() => _flash = t);
      Sfx.play('flip');
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || token != _run) {
        return;
      }
      setState(() => _flash = -1);
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
    if (!mounted || token != _run) {
      return;
    }
    setState(() => _inputEnabled = true);
  }

  void _tap(int i) {
    if (!_inputEnabled) {
      return;
    }
    if (i == widget.level.sequence[_inputIndex]) {
      Sfx.play('tap');
      setState(() => _inputIndex++);
      if (_inputIndex >= widget.level.sequence.length) {
        _inputEnabled = false;
        Sfx.play('match');
        widget.onWin(_mistakes, 0);
      }
    } else {
      _mistakes++;
      Sfx.play('wrong');
      HapticFeedback.mediumImpact();
      _showSequence();
    }
  }

  @override
  void dispose() {
    _run++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.level.sequence.length;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: <Widget>[
              ChipPill(emoji: _inputEnabled ? '👆' : '👀', text: _inputEnabled ? S.t('yourTurn') : S.t('watch')),
              ChipPill(emoji: '🧠', text: '$_inputIndex/$total'),
              ChipPill(emoji: '❌', text: '${S.t('mistakes')}: $_mistakes'),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double cell = ((c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight) - 60) / 3;
              return Center(
                child: SizedBox(
                  width: cell * 3 + 20,
                  height: cell * 3 + 20,
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      for (int i = 0; i < widget.level.tileCount; i++)
                        AnimatedScale(
                          scale: _flash == i ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: GestureDetector(
                            onTap: () => _tap(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: _flash == i ? AppColors.sunYellow : AppColors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _flash == i ? AppColors.sunYellow : AppColors.white.withValues(alpha: 0.25),
                                  width: 3,
                                ),
                                boxShadow: _flash == i
                                    ? <BoxShadow>[BoxShadow(color: AppColors.sunYellow.withValues(alpha: 0.5), blurRadius: 18)]
                                    : <BoxShadow>[],
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(_tileEmojis[i % _tileEmojis.length], style: const TextStyle(fontSize: 44)),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
