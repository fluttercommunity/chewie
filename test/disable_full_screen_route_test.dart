import 'package:chewie/chewie.dart';
import 'package:chewie/src/player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

const src =
    "https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4";

void main() {
  testWidgets(
    "disableFullScreenRoute flips isFullScreen without pushing a route",
    (WidgetTester tester) async {
      final videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(src),
      );
      final chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        autoPlay: false,
        looping: false,
        disableFullScreenRoute: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Chewie(controller: chewieController)),
        ),
      );
      await tester.pump();

      expect(chewieController.disableFullScreenRoute, isTrue);
      expect(chewieController.isFullScreen, isFalse);
      // The player is mounted exactly once.
      expect(find.byType(PlayerWithControls), findsOneWidget);

      // Enter fullscreen: the controller flag flips, but because the route is
      // disabled the player stays mounted in place — no second instance is
      // pushed onto a fullscreen route.
      chewieController.enterFullScreen();
      await tester.pumpAndSettle();

      expect(chewieController.isFullScreen, isTrue);
      expect(find.byType(PlayerWithControls), findsOneWidget);

      // Exit fullscreen: the flag flips back, again without a route pop.
      chewieController.exitFullScreen();
      await tester.pumpAndSettle();

      expect(chewieController.isFullScreen, isFalse);
      expect(find.byType(PlayerWithControls), findsOneWidget);

      chewieController.dispose();
      videoPlayerController.dispose();
    },
  );

  test("disableFullScreenRoute defaults to false", () {
    final videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(src),
    );
    final controller = ChewieController(
      videoPlayerController: videoPlayerController,
    );

    expect(controller.disableFullScreenRoute, isFalse);

    controller.dispose();
    videoPlayerController.dispose();
  });

  test("copyWith carries disableFullScreenRoute", () {
    final videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(src),
    );
    final base = ChewieController(videoPlayerController: videoPlayerController);
    expect(base.disableFullScreenRoute, isFalse);

    final enabled = base.copyWith(disableFullScreenRoute: true);
    expect(enabled.disableFullScreenRoute, isTrue);

    // Omitting the argument preserves the existing value.
    final preserved = enabled.copyWith();
    expect(preserved.disableFullScreenRoute, isTrue);

    base.dispose();
    videoPlayerController.dispose();
  });
}
