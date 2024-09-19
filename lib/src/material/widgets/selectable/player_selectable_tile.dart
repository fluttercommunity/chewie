import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../config/colors.dart';
import '../../../helpers/extensions.dart';

class PlayerSelectableTile extends StatelessWidget {
  const PlayerSelectableTile({
    required this.title,
    required this.onPressed,
    this.isActive = false,
    super.key,
  });

  final String title;
  final bool isActive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: isActive ? PlayerColors.primary : PlayerColors.greyB8,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: isActive
                  ? Container(
                      decoration: const BoxDecoration(
                        color: PlayerColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox(),
            ),
            const Gap(16),
            Builder(
              builder: (context) {
                if (isActive) {
                  return Text(
                    title,
                    style: context.s18.w400,
                  );
                }
                return Text(
                  title,
                  style: context.s18.w400.greyB8,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
