import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fake_video_player_platform.dart';

void main() {
  setUp(() => VideoPlayerPlatform.instance = FakeVideoPlayerPlatform());

  testWidgets('desktop bar keeps the fullscreen button at the right edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = ChewieController(
      videoPlayerController: VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/video.mp4'),
      ),
      customControls: const MaterialDesktopControls(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Chewie(controller: controller)),
      ),
    );
    await tester.pump();

    final fullscreen = tester.getRect(find.byIcon(Icons.fullscreen));
    expect(1280 - fullscreen.right, lessThan(40));
  });
}
