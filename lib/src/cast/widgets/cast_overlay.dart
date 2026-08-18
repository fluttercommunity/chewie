import 'package:chewie/src/cast/cast_device.dart';
import 'package:chewie/src/models/cast_translations.dart';
import 'package:flutter/material.dart';

/// What Chewie shows in place of the video surface while a session is live.
///
/// The local player is paused during a session, so the texture underneath is a
/// frozen frame at best and black at worst; replacing it makes it obvious the
/// picture moved to the TV rather than that playback broke.
///
/// Override it with `ChewieController.castOverlayBuilder` when the app has its
/// own idea of what casting should look like.
class CastOverlay extends StatelessWidget {
  const CastOverlay({
    required this.device,
    required this.translations,
    super.key,
  });

  final CastDevice? device;
  final CastTranslations translations;

  @override
  Widget build(BuildContext context) {
    final name = device?.name;
    final label = name != null
        ? '${translations.castingToText} $name'
        : translations.castButtonTooltip;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cast_connected, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
