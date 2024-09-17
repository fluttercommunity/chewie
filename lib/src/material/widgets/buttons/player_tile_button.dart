import 'package:chewie/src/config/colors.dart';
import 'package:chewie/src/config/icons.dart';
import 'package:chewie/src/helpers/enums/badge_type_enum.dart';
import 'package:chewie/src/helpers/extensions.dart';
import 'package:chewie/src/widgets/badge/put_badge.dart';
import 'package:chewie/src/widgets/svg/svg_asset.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PlayerTileButton extends StatelessWidget {
  const PlayerTileButton({
    required this.onPressed,
    required this.title,
    required this.value,
    required this.icon,
    this.badgeContent,
    this.isShowDivider = true,
    super.key,
  });

  final String icon;
  final String title;
  final String value;
  final String? badgeContent;
  final bool isShowDivider;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            child: Row(
              children: [
                _Icon(content: badgeContent, icon: icon),
                const Gap(16),
                Expanded(
                  child: Text(
                    title,
                    style: context.s18.w400,
                  ),
                ),
                Text(
                  value,
                  style: context.s16.w400.greyB8,
                ),
                const Gap(8),
                const SvgAsset(
                  PlayerIcons.caretRight,
                  color: PlayerColors.greyB8,
                  width: 24,
                  height: 24,
                ),
              ],
            ),
          ),
          if (isShowDivider)
            const Divider(
              height: 1,
              thickness: 1,
              color: PlayerColors.dark36,
            ),
        ],
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.icon, this.content});

  final String? content;
  final String icon;

  @override
  Widget build(BuildContext context) {
    if (content != null) {
      return PutBadge(
        badgeContent: content!,
        badgeType: BadgeType.sheetTile,
        child: SvgAsset(
          icon,
          width: 24,
          height: 24,
        ),
      );
    }
    return SvgAsset(
      icon,
      width: 24,
      height: 24,
    );
  }
}
