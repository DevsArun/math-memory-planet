import 'package:flutter/material.dart';

import 'state.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// First-launch flow: mascot welcome -> language pick -> optional name.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _finish(String name) {
    appState.completeOnboarding(name);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      resizeToAvoidBottomInset: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _step == 0 ? _langStep() : _nameStep(),
      ),
    );
  }

  Widget _langStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Mascot(size: 120),
        const SizedBox(height: 14),
        Text(
          S.t('ob_welcome'),
          style: TextStyle(fontSize: 20, color: AppColors.textDark.withValues(alpha: 0.85)),
        ),
        Text(
          S.t('appTitle'),
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String code in S.codes)
              ChunkyButton(
                color: appState.locale == code ? AppColors.mint : AppColors.textDark.withValues(alpha: 0.08),
                minHeight: 46,
                radius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                onTap: () {
                  appState.setLocale(code);
                  S.locale = code;
                  setState(() {});
                },
                child: Text(
                  S.names[code] ?? code,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: appState.locale == code ? AppColors.textDark : AppColors.textDark,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 26),
        ChunkyButton(
          onTap: () => setState(() => _step = 1),
          child: Text(
            S.t('ob_go'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }

  Widget _nameStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Mascot(size: 100),
        const SizedBox(height: 14),
        Text(
          S.t('ob_name'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.cardFace, borderRadius: BorderRadius.circular(18)),
          child: TextField(
            controller: _nameCtrl,
            maxLength: 12,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Nova',
              counterText: '',
              hintStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.35)),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ChunkyButton(
              color: AppColors.textDark.withValues(alpha: 0.1),
              minHeight: 60,
              onTap: () => _finish(''),
              child: Text(
                S.t('ob_skip'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ),
            const SizedBox(width: 12),
            ChunkyButton(
              color: AppColors.mint,
              minHeight: 60,
              onTap: () => _finish(_nameCtrl.text),
              child: Text(
                S.t('ob_go'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
