import 'package:flutter/material.dart';

import '../../../config/colors.dart';
import '../../../widgets/sheet/player_bottom_sheet.dart';
import '../../widgets/selectable/player_selectable_tile.dart';

class GenericSimpleChooseSheet<T> extends StatelessWidget {
  const GenericSimpleChooseSheet({
    required this.title,
    required this.onPressBack,
    required this.buildItemLabel,
    this.items = const [],
    this.selectedItem,
    this.onItemTap,
    super.key,
  });

  final String title;
  final List<T> items;
  final T? selectedItem;
  final VoidCallback onPressBack;
  final void Function(T item)? onItemTap;
  final String Function(T item) buildItemLabel;

  @override
  Widget build(BuildContext context) {
    return PlayerBottomSheetWrap(
      onPressBack: onPressBack,
      title: title,
      body: Column(
        children: [
          for (final item in items.indexed) ...{
            PlayerSelectableTile(
              onPressed: () => onItemTap?.call(item.$2),
              title: buildItemLabel(item.$2),
              isActive: selectedItem == item.$2,
            ),
            if (items.length - 1 != item.$1)
              const Divider(
                indent: 24,
                endIndent: 24,
                height: 1,
                thickness: 1,
                color: PlayerColors.dark36,
              ),
          },
        ],
      ),
    );
  }
}
