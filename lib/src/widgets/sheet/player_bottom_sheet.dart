import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../config/colors.dart';
import '../../config/icons.dart';
import '../../helpers/extensions.dart';
import '../../material/widgets/buttons/player_icon_button.dart';

Future<void> showPlayerBottomSheet(
  BuildContext context, {
  required Widget child,
}) async {
  return showCupertinoModalBottomSheet<void>(
    context: context,
    shape: BeveledRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    backgroundColor: PlayerColors.dark14,
    useRootNavigator: true,
    builder: (ctx) => PlayerBottomSheet(
      child: child,
    ),
  );
}

class PlayerBottomSheet extends StatelessWidget {
  const PlayerBottomSheet({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PlayerColors.greyB8,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const Gap(16),
            child,
          ],
        ),
      ),
    );
  }
}

class PlayerBottomSheetWrap extends StatelessWidget {
  const PlayerBottomSheetWrap({
    required this.title,
    required this.body,
    this.onPressBack,
    super.key,
  });

  final Widget body;
  final String title;
  final VoidCallback? onPressBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: onPressBack != null
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                if (onPressBack != null)
                  PlayerIconButton(
                    onPressed: () => onPressBack?.call(),
                    icon: PlayerIcons.caretLeft,
                    size: 24,
                  ),
                Text(
                  title,
                  style: context.s20.w600,
                ),
                if (onPressBack != null) const Gap(45),
              ],
            ),
          ),
          const Gap(8),
          Container(
            constraints: BoxConstraints(
              maxHeight: context.height - 120,
            ),
            child: SingleChildScrollView(
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
