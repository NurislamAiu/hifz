import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/app_background.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/player/presentation/widgets/mini_player_bar.dart';
import '../features/progress/presentation/screens/progress_screen.dart';
import '../features/reciters/presentation/screens/reciter_list_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'glass_nav_bar.dart';

final _rootTabIndexProvider = StateProvider<int>((ref) => 0);

class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  static const _screens = [
    HomeScreen(),
    ProgressScreen(embedded: true),
    ReciterListScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(_rootTabIndexProvider);

    return Scaffold(
      extendBody: true,
      body: AppBackground(
        child: Stack(
          children: [
            IndexedStack(index: index, children: _screens),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniPlayerBar(),
                  GlassNavBar(
                    currentIndex: index,
                    onTap: (i) => ref.read(_rootTabIndexProvider.notifier).state = i,
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
