import 'package:flutter/material.dart';

import 'assets.dart';
import 'game_shell.dart';
import 'models.dart';
import 'onboarding.dart';
import 'parent_screens.dart';
import 'sfx.dart';
import 'state.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appState.load();
  S.locale = appState.locale;
  Sfx.enabled = !appState.muted;
  runApp(const MMPApp());
}

class MMPApp extends StatelessWidget {
  const MMPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'Math Memory Planet',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C4FD8),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: appState.onboardingDone ? const HomeScreen() : const OnboardingScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openSettings(BuildContext context) async {
    final bool ok = await showParentGate(context);
    if (!context.mounted || !ok) {
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final List<int> daily = dailyLevelFor(DateTime.now());
    final ModeInfo dailyMode = kModes[daily[0]];
    return GradientScaffold(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight, minWidth: box.maxWidth),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: <Widget>[
                const Mascot(size: 58),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        appState.childName.isEmpty ? S.t('appTitle') : '${S.t('hi')}, ${appState.childName}!',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        S.t('choosePlanet'),
                        style: TextStyle(fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _RoundIconButton(
                  icon: Icons.settings_rounded,
                  onTap: () => _openSettings(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: <Widget>[
                ChipPill(emoji: '🔥', text: '${appState.streak}'),
                const SizedBox(width: 8),
                ChipPill(emoji: '⭐', text: '${appState.totalStars}'),
                const SizedBox(width: 8),
                ChipPill(emoji: '🏅', text: '${appState.badges.length}/${AppState.badgeDefs.length}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: ChunkyButton(
              color: AppColors.lavender,
              gradient: const LinearGradient(colors: <Color>[Color(0xFFB9A7F9), Color(0xFFFFB3E2)]),
              minHeight: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GameScreen(modeIndex: daily[0], levelIndex: daily[1]),
                  ),
                );
              },
              child: Row(
                children: <Widget>[
                  const Text('☄️', style: TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          S.t('daily'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
                        ),
                        Text(
                          '${dailyMode.emoji} ${S.t(dailyMode.titleKey)} • ${S.t('level')} ${daily[1] + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_arrow_rounded, color: AppColors.textDark, size: 34),
                ],
              ),
            ),
          ),
            ]),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                childAspectRatio: 1.55,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
              ),
              children: <Widget>[
                for (int i = 0; i < kModes.length; i++) ModeCard(modeIndex: i),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ChunkyButton(
              color: AppColors.mint,
              gradient: const LinearGradient(colors: <Color>[Color(0xFF4ECDC4), Color(0xFF45B7FF)]),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RewardsScreen()));
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('🏆', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Text(
                    S.t('rewards'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ),
        ],
          ),
        ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Sfx.play('button');
        onTap();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.textDark.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textDark, size: 28),
      ),
    );
  }
}

class ModeCard extends StatelessWidget {
  const ModeCard({super.key, required this.modeIndex});

  final int modeIndex;

  @override
  Widget build(BuildContext context) {
    final ModeInfo mode = kModes[modeIndex];
    final int earned = appState.starsForMode(modeIndex);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + modeIndex * 70),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double v, Widget? child) {
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 26 * (1 - v)), child: child),
        );
      },
      child: ChunkyButton(
        color: Colors.white,
        padding: const EdgeInsets.all(14),
      minHeight: 0,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LevelSelectScreen(modeIndex: modeIndex)));
      },
      child: Row(
        children: <Widget>[
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Color(mode.color).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(A.planet(modeIndex), width: 76, height: 76),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  S.t(mode.titleKey),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: earned / 90,
                    minHeight: 8,
                    backgroundColor: AppColors.textDark.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(mode.color)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '⭐ $earned/90',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
          ),
        ),
    );
  }
}
