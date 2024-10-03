import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../../chewie.dart';

class MaterialGesture extends StatefulWidget {
  const MaterialGesture({
    required this.restartTimer,
    required this.controller,
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;
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
    return SafeArea(
      minimum: const EdgeInsets.symmetric(
        vertical: 60,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.onTap,
              onDoubleTap: () async {
                final position =
                    (await widget.controller.videoPlayerController.position) ??
                        Duration.zero;
                widget.restartTimer();
                await widget.controller.seekTo(
                  position + (-10).seconds,
                );
              },
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta == null) return;

                changeDeviceBrightness(details.primaryDelta!);

                widget.restartTimer();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: widget.onTap,
              onDoubleTap: () async {
                final position =
                    (await widget.controller.videoPlayerController.position) ??
                        Duration.zero;
                widget.restartTimer();
                await widget.controller.seekTo(
                  position + 10.seconds,
                );
              },
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta == null) return;

                changeDeviceVolume(details.primaryDelta!);

                widget.restartTimer();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
