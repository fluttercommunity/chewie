import 'package:chewie/src/config/colors.dart';
import 'package:chewie/src/helpers/enums/badge_type_enum.dart';
import 'package:chewie/src/helpers/extensions.dart';
import 'package:flutter/material.dart';

class PlayerBadge extends StatelessWidget {
  const PlayerBadge({
    required this.content,
    required this.type,
    super.key,
  });

  final BadgeType type;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: type.widgetHeight,
      width: type.widgetWidth,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      decoration: BoxDecoration(
        color: PlayerColors.primary,
        borderRadius: BorderRadius.circular(
          1.4,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          content,
          style: context.s18.white,
        ),
      ),
    );
  }
}
