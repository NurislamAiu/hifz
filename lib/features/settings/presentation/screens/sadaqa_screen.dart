import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';

// ─────────────────────────────────────────────────────────────────────────
// TODO(owner): замените плейсхолдеры на свои реквизиты. Пустые строки просто
// не показываются, так что можно оставить только те способы, что вам нужны.
const _recipientName = 'Нур Ислам';
const _kaspiCard = '4400 4303 4060 8337';
const _kaspiPhone = '+7 747 319 3061';
const _bankCard = '';
// Kaspi payment / QR deeplink, например 'https://kaspi.kz/pay/xxxx'. Если задан —
// покажется кнопка «Открыть в Kaspi».
const _kaspiPayUrl = '';
// ─────────────────────────────────────────────────────────────────────────

class SadaqaScreen extends StatelessWidget {
  const SadaqaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: SoftPalette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Row(
              children: [
                _CircleButton(
                  icon: Iconsax.arrow_left_2,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Text(
                  s.sadaqa,
                  style: AppTextStyles.displayTitle.copyWith(
                    color: SoftPalette.textDark,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _HeroCard(),
            const SizedBox(height: 16),
            const _AyahCard(),
            const SizedBox(height: 16),
            _RequisitesCard(),
            const SizedBox(height: 16),
            Text(
              s.sadaqaFooter,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: SoftPalette.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: SoftPalette.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: SoftPalette.softShadow(opacity: 0.16, y: 12, blur: 26),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 12,
              child: Icon(
                FlutterIslamicIcons.zakat,
                size: 56,
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FlutterIslamicIcons.zakat,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.s.supportProject,
                    style: AppTextStyles.title.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.s.sadaqaHeroText,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.45,
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

class _AyahCard extends StatelessWidget {
  const _AyahCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'مَّثَلُ ٱلَّذِينَ يُنفِقُونَ أَمْوَٰلَهُمْ فِى سَبِيلِ ٱللَّهِ كَمَثَلِ حَبَّةٍ '
              'أَنۢبَتَتْ سَبْعَ سَنَابِلَ فِى كُلِّ سُنۢبُلَةٍ مِّا۟ئَةُ حَبَّةٍ',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.arabic.copyWith(
                color: SoftPalette.textDark,
                fontSize: 20,
                height: 1.9,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.s.sadaqaAyahTranslation,
              textAlign: TextAlign.center,
              style: AppTextStyles.transliteration.copyWith(
                color: SoftPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.s.baqarahReference,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: SoftPalette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequisitesCard extends StatelessWidget {
  const _RequisitesCard();

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    void add(IconData icon, String label, String value) {
      if (value.isEmpty) return;
      if (rows.isNotEmpty) rows.add(const _RowDivider());
      rows.add(_CopyRow(icon: icon, label: label, value: value));
    }

    final s = context.s;
    add(Iconsax.user, s.recipient, _recipientName);
    add(Iconsax.card, 'Kaspi Gold', _kaspiCard);
    add(Iconsax.call, s.phoneTransfer, _kaspiPhone);
    add(Iconsax.card, s.bankCard, _bankCard);

    final requisites = rows.isEmpty
        ? const _EmptyRequisites()
        : _Card(child: Column(children: rows));

    return Column(
      children: [
        requisites,
        if (_kaspiPayUrl.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: SoftPalette.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () async {
                final uri = Uri.parse(_kaspiPayUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Iconsax.card_send, size: 20),
              label: Text(
                context.s.openKaspi,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyRequisites extends StatelessWidget {
  const _EmptyRequisites();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SoftPalette.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.info_circle,
                color: SoftPalette.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                context.s.requisitesSoon,
                style: AppTextStyles.body.copyWith(
                  color: SoftPalette.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.s.copied(label)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: SoftPalette.primaryDark,
              duration: const Duration(seconds: 2),
            ),
          );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SoftPalette.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: SoftPalette.primary, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: SoftPalette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.body.copyWith(
                      color: SoftPalette.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.copy, color: SoftPalette.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: SoftPalette.softShadow(),
      ),
      child: Material(
        color: SoftPalette.surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      endIndent: 16,
      color: SoftPalette.track,
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SoftPalette.surface,
          shape: BoxShape.circle,
          boxShadow: SoftPalette.softShadow(opacity: 0.05, y: 4, blur: 10),
        ),
        child: Icon(icon, size: 16, color: SoftPalette.primary),
      ),
    );
  }
}
