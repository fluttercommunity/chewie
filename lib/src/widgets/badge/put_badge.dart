import 'package:flutter/material.dart';

import '../../helpers/enums/badge_type_enum.dart';
import 'badge.dart';

class PutBadge extends StatelessWidget {
  const PutBadge({
    required this.child,
    required this.badgeContent,
    required this.badgeType,
    super.key,
  });

  final Widget child;
  final String badgeContent;
  final BadgeType badgeType;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: badgeType.right,
          top: badgeType.top,
          child: PlayerBadge(
            content: badgeContent,
            type: badgeType,
          ),
        ),
      ],
    );
  }
}
