import 'dart:async';

import 'package:double_tap_player_view/double_tap_player_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../../chewie.dart';
import '../../config/colors.dart';
import '../../helpers/extensions.dart';

class MaterialGesture extends StatefulWidget {
  const MaterialGesture({
    required this.restartTimer,
    required this.controller,
    super.key,
  });

  final VoidCallback restartTimer;
  final ChewieController controller;

  @override
  State<MaterialGesture> createState() => _MaterialGestureState();
}

class _MaterialGestureState extends State<MaterialGesture> {
  double brightness = 0.5;
  double deviceVolume = 0.5;
  bool isShowHandle = false;
  Timer? timer;

  double getValue(double value, double speed) {
    var result = value;

    if (result >= 1) {
      result = 1;
    } else if (result >= 0) {
      result -= speed;
    }

    if (result < 0.0) {
      result = 0.0;
    } else if (result <= 1) {
      result -= speed;
    }

    return result;
  }

  void changeDeviceBrightness(double delta) {
    final deltaSpeed = delta / 1500;

    brightness = getValue(
      brightness,
      deltaSpeed,
    );

    ScreenBrightness().setScreenBrightness(
      brightness >= 1 ? 1 : brightness,
    );
  }

  void changeDeviceVolume(double delta) {
    final deltaSpeed = delta / 1500;

    deviceVolume = getValue(
      deviceVolume,
      deltaSpeed,
    );

    VolumeController().setVolume(
      deviceVolume,
    );
  }

  Future<void> setCurrentBrightness() async {
    try {
      brightness = await ScreenBrightness().current;
    } catch (e) {
      brightness = 0;
    }
  }

  Future<void> setCurrentVolume() async {
    try {
      deviceVolume = await VolumeController().getVolume();
    } catch (e) {
      deviceVolume = 0;
    }
  }

  @override
  void initState() {
    setCurrentBrightness();
    setCurrentVolume();

    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta == null) return;

        if (details.globalPosition.dx < context.width / 2) {
          changeDeviceBrightness(details.primaryDelta!);
        } else {
          changeDeviceVolume(details.primaryDelta!);
        }

        widget.restartTimer();
      },
      child: DoubleTapPlayerView(
        doubleTapConfig: DoubleTapConfig.create(
          iconRight: const Icon(
            Icons.fast_forward_rounded,
            size: 40,
            color: PlayerColors.white,
          ),
          iconLeft: const Icon(
            Icons.fast_rewind_rounded,
            size: 40,
            color: PlayerColors.white,
          ),
          onDoubleTap: (lr) async {
            final position =
                (await widget.controller.videoPlayerController.position) ??
                    Duration.zero;
            widget.restartTimer();
            await widget.controller.seekTo(
              position + (lr == Lr.RIGHT ? 10.seconds : -10.seconds),
            );
          },
        ),
        child: const ColoredBox(color: Colors.transparent),
      ),
    );
  }
}
