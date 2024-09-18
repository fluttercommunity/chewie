import 'package:flutter/material.dart';

import '../../../widgets/svg/svg_asset.dart';

class PlayerIconButton extends StatelessWidget {
  const PlayerIconButton({
    required this.onPressed,
    required this.icon,
    this.size = 32,
    super.key,
  });

  final String icon;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 6,
      height: size + 6,
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
}
