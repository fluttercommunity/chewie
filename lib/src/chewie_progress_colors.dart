import 'package:flutter/rendering.dart';

class ChewieProgressColors {
  final Paint playedPaint;
  final Paint bufferedPaint;
  final Paint handlePaint;
  final Paint disabledPaint;

  ChewieProgressColors({
    Color playedColor: const Color.fromRGBO(255, 0, 0, 0.7),
    Color bufferedColor: const Color.fromRGBO(30, 30, 200, 0.2),
    Color handleColor: const Color.fromRGBO(200, 200, 200, 1.0),
    Color disabledColor: const Color.fromRGBO(200, 200, 200, 0.5),
  })
      : playedPaint = new Paint()..color = playedColor,
        bufferedPaint = new Paint()..color = bufferedColor,
        handlePaint = new Paint()..color = handleColor,
        disabledPaint = new Paint()..color = disabledColor;
}
