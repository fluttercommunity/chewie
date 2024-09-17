import 'package:chewie/src/config/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SvgAsset extends StatelessWidget {
  const SvgAsset(
    this.assetName, {
    this.color = PlayerColors.white,
    this.height = 32,
    this.width = 32,
    super.key,
  });

  final Color color;
  final double width;
  final double height;
  final String assetName;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetName,
      width: width,
      height: height,
      package: 'chewie',
      colorFilter: ColorFilter.mode(
        color,
        BlendMode.srcIn,
      ),
    );
  }
}
