import 'package:chewie/src/helpers/enums/badge_type_enum.dart';
import 'package:chewie/src/widgets/badge/put_badge.dart';
import 'package:chewie/src/widgets/svg/svg_asset.dart';
import 'package:flutter/material.dart';

class PlayerIconButtonWithBadge extends StatelessWidget {
  const PlayerIconButtonWithBadge({
    required this.onPressed,
    required this.icon,
    required this.badgeContent,
    required this.badgeType,
    this.size = 32,
    super.key,
  });

  final String icon;
  final double size;
  final VoidCallback onPressed;
  final String? badgeContent;
  final BadgeType badgeType;

  @override
  Widget build(BuildContext context) {
    if (badgeContent != null) {
      return PutBadge(
        badgeContent: badgeContent!,
        badgeType: badgeType,
        child: IconButton(
          onPressed: onPressed,
          icon: SvgAsset(
            icon,
            width: size,
            height: size,
          ),
        ),
      );
    }
    return IconButton(
      onPressed: onPressed,
      icon: SvgAsset(
        icon,
        width: size,
        height: size,
      ),
    );
  }
}
