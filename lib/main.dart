import 'package:flutter/material.dart';

import 'game_shell.dart';
import 'models.dart';
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
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
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
    return GradientScaffold(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        S.t('appTitle'),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        S.t('choosePlanet'),
                        style: TextStyle(fontSize: 15, color: AppColors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                ChipPill(emoji: '🔥', text: '${appState.streak}'),
                const SizedBox(width: 8),
                ChipPill(emoji: '⭐', text: '${appState.totalStars}'),
                const SizedBox(width: 8),
                _RoundIconButton(
                  icon: Icons.settings_rounded,
                  onTap: () => _openSettings(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView(
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ChunkyButton(
              color: AppColors.mint,
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
          color: AppColors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 28),
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
    return ChunkyButton(
      color: AppColors.cardFace,
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
              color: Color(mode.color).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(mode.emoji, style: const TextStyle(fontSize: 44))),
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
    );
  }
}
