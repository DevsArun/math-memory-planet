import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'sfx.dart';
import 'state.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Multiply-two-numbers parental gate. Returns true when solved.
Future<bool> showParentGate(BuildContext context) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _GateDialog(),
  );
  return ok ?? false;
}

class _GateDialog extends StatefulWidget {
  const _GateDialog();

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> with SingleTickerProviderStateMixin {
  final Random _rng = Random();
  late int _a;
  late int _b;
  late List<int> _options;
  int _wrong = 0;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _newQuestion() {
    _a = 6 + _rng.nextInt(4);
    _b = 6 + _rng.nextInt(4);
    final int correct = _a * _b;
    final Set<int> opts = <int>{correct};
    final List<int> deltas = <int>[1, -1, 2, -2, 10, -10, 3, -3]..shuffle(_rng);
    for (final int d in deltas) {
      if (opts.length >= 4) {
        break;
      }
      final int v = correct + d;
      if (v > 0 && !opts.contains(v)) {
        opts.add(v);
      }
    }
    _options = opts.toList()..shuffle(_rng);
  }

  void _pick(int v) {
    if (v == _a * _b) {
      Sfx.play('match');
      Navigator.of(context).pop(true);
    } else {
      Sfx.play('wrong');
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
      setState(() {
        _wrong++;
        if (_wrong >= 3) {
          _wrong = 0;
          _newQuestion();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (BuildContext context, Widget? child) {
        final double dx = sin(_shake.value * pi * 4) * 12 * (1 - _shake.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: AlertDialog(
        backgroundColor: AppColors.cardFace,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          S.t('parentGate'),
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                S.t('gateHint'),
                style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 14),
              Text(
                '$_a × $_b = ?',
                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: <Widget>[
                  for (final int v in _options)
                    ChunkyButton(
                      color: AppColors.sky,
                      minHeight: 56,
                      onTap: () => _pick(v),
                      child: Text(
                        '$v',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.white),
                      ),
                    ),
                ],
              ),
              if (_wrong > 0) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  S.t('tryAgain'),
                  style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w800),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.title, this.subtitle, this.trailing, this.onTap});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ChunkyButton(
        color: AppColors.white.withValues(alpha: 0.14),
        minHeight: 60,
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        onTap: onTap ?? () {},
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.white),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: 0.7)),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Settings (parental gated): language, sound, stats, privacy, about, reset.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardFace,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          S.t('appTitle'),
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
        content: Text(
          '${S.t('about')} • v$kAppVersion\n\n${S.t('privacyBody')}',
          style: const TextStyle(color: AppColors.textDark, height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(S.t('cancel')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardFace,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          S.t('resetProgress'),
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
        content: Text(S.t('resetConfirm'), style: const TextStyle(color: AppColors.textDark)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              S.t('yesReset'),
              style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      appState.resetAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: <Widget>[
          _Header(title: S.t('settings')),
          Expanded(
            child: AnimatedBuilder(
              animation: appState,
              builder: (BuildContext context, Widget? child) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    SectionTitle(text: S.t('language')),
                    for (final String code in S.codes)
                      _SettingTile(
                        title: S.names[code] ?? code,
                        trailing: appState.locale == code
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 26)
                            : null,
                        onTap: () {
                          appState.setLocale(code);
                          S.locale = code;
                        },
                      ),
                    SectionTitle(text: S.t('sound')),
                    _SettingTile(
                      title: S.t('sound'),
                      trailing: Switch(
                        value: !appState.muted,
                        activeColor: AppColors.mint,
                        onChanged: (bool v) {
                          appState.setMuted(!v);
                          Sfx.enabled = v;
                        },
                      ),
                      onTap: () {
                        final bool newMuted = !appState.muted;
                        appState.setMuted(newMuted);
                        Sfx.enabled = !newMuted;
                      },
                    ),
                    SectionTitle(text: S.t('statsTitle')),
                    _SettingTile(
                      title: S.t('statsTitle'),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.white),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const StatsScreen()),
                        );
                      },
                    ),
                    SectionTitle(text: S.t('privacy')),
                    _SettingTile(
                      title: S.t('privacy'),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.white),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const PrivacyPage()),
                        );
                      },
                    ),
                    _SettingTile(
                      title: S.t('about'),
                      subtitle: 'v$kAppVersion',
                      onTap: () => _showAbout(context),
                    ),
                    const SizedBox(height: 12),
                    _SettingTile(
                      title: S.t('resetProgress'),
                      trailing: const Icon(Icons.delete_forever_rounded, color: AppColors.coral),
                      onTap: () => _confirmReset(context),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.emoji, required this.label, required this.value});

  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white),
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.75)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Parent stats (behind the gate).
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: <Widget>[
          _Header(title: S.t('statsTitle')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 190,
                    childAspectRatio: 1.7,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  children: <Widget>[
                    _StatCard(emoji: '🎮', label: S.t('gamesPlayed'), value: '${appState.gamesPlayed}'),
                    _StatCard(emoji: '✅', label: S.t('level'), value: '${appState.levelsCompleted}/210'),
                    _StatCard(emoji: '⭐', label: S.t('stars'), value: '${appState.totalStars}/630'),
                    _StatCard(emoji: '🔥', label: S.t('streak'), value: '${appState.streak}'),
                    _StatCard(
                      emoji: '⏱️',
                      label: S.t('timePlayed'),
                      value: '${appState.totalSeconds ~/ 60} ${S.t('minutes')}',
                    ),
                    _StatCard(emoji: '❌', label: S.t('mistakes'), value: '${appState.totalMistakes}'),
                  ],
                ),
                const SizedBox(height: 14),
                for (int i = 0; i < kModes.length; i++)
                  _SettingTile(
                    title: '${kModes[i].emoji} ${S.t(kModes[i].titleKey)}',
                    trailing: Text(
                      '${appState.modePlays[i] ?? 0} 🎮  ${appState.starsForMode(i)}/90 ⭐',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.white),
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

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.def, required this.unlocked});

  final BadgeDef def;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.cardFace : AppColors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked ? AppColors.sunYellow : AppColors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(def.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 4),
          Text(
            S.t(def.nameKey),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: unlocked ? AppColors.textDark : AppColors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardOption extends StatelessWidget {
  const _RewardOption({
    required this.locked,
    required this.selected,
    required this.cost,
    required this.preview,
    required this.onTap,
  });

  final bool locked;
  final bool selected;
  final int cost;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      color: selected ? AppColors.sunYellow : AppColors.white.withValues(alpha: 0.14),
      minHeight: 0,
      radius: 18,
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          preview,
          const SizedBox(height: 6),
          Text(
            locked
                ? '🔒 ${S.t('unlockAt').replaceAll('{n}', '$cost')}'
                : selected
                    ? '✓ ${S.t('selected')}'
                    : S.t('select'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.textDark : AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Free cosmetic rewards unlocked by total stars. Kid-facing, no gate.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: <Widget>[
          _Header(title: S.t('rewards')),
          Expanded(
            child: AnimatedBuilder(
              animation: appState,
              builder: (BuildContext context, Widget? child) {
                final int total = appState.totalStars;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ChipPill(emoji: '⭐', text: '$total'),
                    ),
                    SectionTitle(text: S.t('trophies')),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 150,
                        childAspectRatio: 1.12,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      children: <Widget>[
                        for (final BadgeDef def in AppState.badgeDefs)
                          _BadgeTile(def: def, unlocked: appState.badges.contains(def.key)),
                      ],
                    ),
                    SectionTitle(text: S.t('cardBacks')),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 130,
                        childAspectRatio: 0.9,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      children: <Widget>[
                        for (int i = 0; i < AppState.cardBacks.length; i++)
                          _RewardOption(
                            locked: total < AppState.cardBackCost[i],
                            selected: appState.cardBack == i,
                            cost: AppState.cardBackCost[i],
                            preview: Container(
                              height: 56,
                              width: 76,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[Color(AppState.cardBacks[i][0]), Color(AppState.cardBacks[i][1])],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(AppState.cardBackEmojis[i], style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                            onTap: () {
                              if (total >= AppState.cardBackCost[i]) {
                                appState.selectCardBack(i);
                                Sfx.play('star');
                              } else {
                                Sfx.play('wrong');
                              }
                            },
                          ),
                      ],
                    ),
                    SectionTitle(text: S.t('themes')),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 130,
                        childAspectRatio: 0.9,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      children: <Widget>[
                        for (int i = 0; i < AppState.themes.length; i++)
                          _RewardOption(
                            locked: total < AppState.themeCost[i],
                            selected: appState.theme == i,
                            cost: AppState.themeCost[i],
                            preview: Container(
                              height: 56,
                              width: 76,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[Color(AppState.themes[i][0]), Color(AppState.themes[i][1])],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onTap: () {
                              if (total >= AppState.themeCost[i]) {
                                appState.selectTheme(i);
                                Sfx.play('star');
                              } else {
                                Sfx.play('wrong');
                              }
                            },
                          ),
                      ],
                    ),
                    SectionTitle(text: S.t('confetti')),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 130,
                        childAspectRatio: 0.9,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      children: <Widget>[
                        for (int i = 0; i < AppState.confettiEmojis.length; i++)
                          _RewardOption(
                            locked: total < AppState.confettiCost[i],
                            selected: appState.confetti == i,
                            cost: AppState.confettiCost[i],
                            preview: Center(
                              child: Text(AppState.confettiEmojis[i], style: const TextStyle(fontSize: 40)),
                            ),
                            onTap: () {
                              if (total >= AppState.confettiCost[i]) {
                                appState.selectConfetti(i);
                                Sfx.play('star');
                              } else {
                                Sfx.play('wrong');
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// In-app privacy policy viewer. No external links anywhere in the app.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: <Widget>[
          _Header(title: S.t('privacy')),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardFace,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  S.t('privacyBody'),
                  style: const TextStyle(fontSize: 16, height: 1.45, color: AppColors.textDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
