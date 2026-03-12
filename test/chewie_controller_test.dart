import 'package:chewie/chewie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

void main() {
  group('ChewieController', () {
    late VideoPlayerController videoPlayerController;

    setUp(() {
      videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/video.mp4'),
      );
    });

    test('sets useNativeWebFullscreen to true by default', () {
      final controller = ChewieController(
        videoPlayerController: videoPlayerController,
      );

      expect(controller.useNativeWebFullscreen, true);

      controller.dispose();
    });

    test('assigns unique textureId to each controller', () {
      final controller1 = ChewieController(
        videoPlayerController: videoPlayerController,
      );
      final controller2 = ChewieController(
        videoPlayerController: videoPlayerController,
      );

      expect(controller1.textureId, isNot(controller2.textureId));

      controller1.dispose();
      controller2.dispose();
    });

    test('toggleFullScreen toggles isFullScreen on non-web', () {
      final controller = ChewieController(
        videoPlayerController: videoPlayerController,
      );

      expect(controller.isFullScreen, false);
      controller.toggleFullScreen();
      expect(controller.isFullScreen, true);
      controller.toggleFullScreen();
      expect(controller.isFullScreen, false);

      controller.dispose();
    });

    test('copyWith preserves useNativeWebFullscreen', () {
      final controller = ChewieController(
        videoPlayerController: videoPlayerController,
        useNativeWebFullscreen: false,
      );

      expect(controller.useNativeWebFullscreen, false);

      final copied = controller.copyWith(useNativeWebFullscreen: true);
      expect(copied.useNativeWebFullscreen, true);

      controller.dispose();
      copied.dispose();
    });
  });
}
