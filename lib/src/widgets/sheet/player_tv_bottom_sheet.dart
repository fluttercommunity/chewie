import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../config/colors.dart';
import '../../helpers/extensions.dart';

Future<T?> showTvBottomSheet<T>(
  BuildContext context, {
  required Widget child,
}) async {
  return showCupertinoModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return TapRegion(
        onTapOutside: (event) {
          Navigator.pop(context);
        },
        child: PlayerTvBottomSheetWrap(
          child: child,
        ),
      );
    },
  );
}

class PlayerTvBottomSheetWrap extends StatelessWidget {
  const PlayerTvBottomSheetWrap({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: context.vw(540),
        height: context.vw(540),
        padding: EdgeInsets.all(
          context.vw(40),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            context.vw(16),
          ),
          color: PlayerColors.dark14,
        ),
        child: child,
      ),
    );
  }
}
