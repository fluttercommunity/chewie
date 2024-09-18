import 'package:flutter/rendering.dart';

import 'config/colors.dart';

class ChewieProgressColors {
  ChewieProgressColors({
    Color playedColor = PlayerColors.primary,
    Color bufferedColor = PlayerColors.greyB8,
    Color handleColor = PlayerColors.primary,
    Color backgroundColor = PlayerColors.white,
  })  : playedPaint = Paint()..color = playedColor,
        bufferedPaint = Paint()..color = bufferedColor,
        handlePaint = Paint()..color = handleColor,
        backgroundPaint = Paint()..color = backgroundColor;

  final Paint playedPaint;
  final Paint bufferedPaint;
  final Paint handlePaint;
  final Paint backgroundPaint;
}
