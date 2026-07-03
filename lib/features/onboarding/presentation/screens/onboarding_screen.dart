import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/providers/settings_provider.dart';

class _OnboardingPageData {
  final String image;
  final String headline;
  final String subtitle;

  const _OnboardingPageData({required this.image, required this.headline, required this.subtitle});
}

const _pages = [
  _OnboardingPageData(
    image: 'assets/images/onboarding/onboarding_1.png',
    headline: 'Слушайте Коран',
    subtitle: 'Аяты в исполнении лучших чтецов. Слушайте офлайн — где бы вы ни были.',
  ),
  _OnboardingPageData(
    image: 'assets/images/onboarding/onboarding_2.png',
    headline: 'Учите аяты наизусть',
    subtitle: 'Зацикливайте любой аят и повторяйте столько раз, сколько нужно для хифза.',
  ),
  _OnboardingPageData(
    image: 'assets/images/onboarding/onboarding_3.png',
    headline: 'Полностью бесплатно',
    subtitle:
        'Без рекламы и подписок — и всегда будет так. Если приложение помогло, вы можете сделать садака в поддержку труда команды.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;

  void _finish() => ref.read(settingsControllerProvider.notifier).completeOnboarding();

  void _next() {
    _controller.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _OnboardingPage(data: _pages[i]),
          ),
          if (!_isLast)
            Positioned(
              top: topInset + 12,
              right: 16,
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(foregroundColor: Colors.white.withValues(alpha: 0.85)),
                child: const Text('Пропустить'),
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomInset + 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _index ? Colors.white : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLast ? _finish : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: Text(
                      _isLast ? 'Начать' : 'Далее',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});
  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(data.image, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.18, 0.62, 1.0],
              colors: [
                Color(0xCC0A0E1A),
                Colors.transparent,
                Color(0xCC0A0E1A),
                Color(0xFF0A0E1A),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 190),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.headline,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: 15.5,
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
