import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';

class FullscreenController {
  void toggleFullscreen(int textureId) {

    final videoElement = web.document.getElementById('videoElement-$textureId');

    if (videoElement == null) {
      // As a fallback, we try to find ANY video element. This is not robust if there are multiple videos.
      final fallbackVideoElement = web.document.querySelector('video');
      if (fallbackVideoElement != null) {
        _requestFullscreen(fallbackVideoElement);
      } else {
        debugPrint('Error: No video element found for fullscreen toggle.');
      }
      return;
    }

    _requestFullscreen(videoElement);
  }

  void _requestFullscreen(web.Element videoElement) {
    if (web.document.fullscreenElement == null) {
      try {
        videoElement.requestFullscreen();
      } catch (e) {
        debugPrint('Error requesting fullscreen: $e');
      }
    } else {
      web.document.exitFullscreen();
    }
  }
}

