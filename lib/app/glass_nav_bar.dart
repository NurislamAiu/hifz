import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

import '../core/localization/app_strings.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/soft_palette.dart';

class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final items = [
      (icon: Iconsax.home_2, label: s.navHome),
      (icon: Iconsax.chart_2, label: s.navStats),
      (icon: FlutterIslamicIcons.quran, label: s.navReciters),
      (icon: FlutterIslamicIcons.tasbih, label: s.navZikr),
      (icon: Iconsax.setting_2, label: s.navSettings),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: SoftPalette.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          ...SoftPalette.softShadow(opacity: 0.10, y: 10, blur: 24),
          BoxShadow(
            color: SoftPalette.primary.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < items.length; i++)
            _NavItem(
              item: items[i],
              selected: i == currentIndex,
              onTap: () {
                if (i != currentIndex) HapticFeedback.selectionClick();
                onTap(i);
              },
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, String label}) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 16 : 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected ? SoftPalette.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: SoftPalette.primary.withValues(alpha: 0.32),
                    offset: const Offset(0, 6),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: selected ? 1 : 0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (context, t, child) {
                return Transform.scale(scale: 1 + (t * 0.12), child: child);
              },
              child: Icon(
                item.icon,
                color: selected ? Colors.white : SoftPalette.textSecondary,
                size: 21,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Text(
                        item.label,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox(height: 21),
            ),
          ],
        ),
      ),
    );
  }
}
