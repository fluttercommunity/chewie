import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

ChewieController buildController({
  bool? swipeToExitFullscreen,
  double? swipeThreshold,
}) {
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video.mp4'),
    ),
    autoPlay: false,
    looping: false,
    swipeToExitFullscreen: swipeToExitFullscreen ?? true,
    swipeThreshold: swipeThreshold ?? 300,
  );
}

/// The [GestureDetector] the fullscreen route wraps the video in when
/// [ChewieController.swipeToExitFullscreen] is enabled.
final Finder swipeArea = find.byWidgetPredicate(
  (widget) => widget is GestureDetector && widget.onVerticalDragEnd != null,
);

/// The black backdrop the fullscreen route always paints behind the video,
/// with or without the swipe gesture. The player's own route is offstage while
/// the fullscreen route is up, so this only ever matches the fullscreen one.
final Finder fullScreenBackground = find.byWidgetPredicate(
  (widget) => widget is Container && widget.color == Colors.black,
);

extension on WidgetTester {
  Future<void> pumpFullScreen(ChewieController controller) async {
    await pumpWidget(
      MaterialApp(
        home: Scaffold(body: Chewie(controller: controller)),
      ),
    );
    await pump();

    controller.enterFullScreen();
    // Let the fullscreen route finish its push transition.
    await pump();
    await pump(const Duration(seconds: 1));
  }

  /// Flings vertically over the fullscreen video with the given velocity in
  /// pixels per second. A positive [velocity] is a downward swipe.
  Future<void> swipeVertically(double velocity) async {
    // A long enough travel for the velocity tracker to settle on [velocity],
    // while staying inside the 800x600 test surface.
    const double distance = 250;
    await fling(
      swipeArea,
      Offset(0, velocity.isNegative ? -distance : distance),
      velocity.abs(),
    );
    await pump();
    await pump(const Duration(seconds: 1));
  }
}

void main() {
  group('swipe to exit fullscreen', () {
    testWidgets('a downward swipe above the threshold exits fullscreen', (
      tester,
    ) async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await tester.pumpFullScreen(controller);
      expect(controller.isFullScreen, isTrue);
      expect(swipeArea, findsOneWidget);

      await tester.swipeVertically(1000);

      expect(controller.isFullScreen, isFalse);
      expect(swipeArea, findsNothing);
    });

    testWidgets('a downward swipe below the threshold stays in fullscreen', (
      tester,
    ) async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await tester.pumpFullScreen(controller);

      await tester.swipeVertically(200);

      expect(controller.isFullScreen, isTrue);
      expect(swipeArea, findsOneWidget);
    });

    testWidgets('an upward swipe never exits fullscreen', (tester) async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await tester.pumpFullScreen(controller);

      await tester.swipeVertically(-1000);

      expect(controller.isFullScreen, isTrue);
      expect(swipeArea, findsOneWidget);
    });

    testWidgets('swipeThreshold defines the velocity that exits fullscreen', (
      tester,
    ) async {
      final controller = buildController(swipeThreshold: 2000);
      addTearDown(controller.dispose);

      await tester.pumpFullScreen(controller);

      // Fast enough for the default threshold, too slow for this one.
      await tester.swipeVertically(1000);
      expect(controller.isFullScreen, isTrue);

      await tester.swipeVertically(3000);
      expect(controller.isFullScreen, isFalse);
    });

    testWidgets('swipeToExitFullscreen: false leaves the gesture unwired', (
      tester,
    ) async {
      final controller = buildController(swipeToExitFullscreen: false);
      addTearDown(controller.dispose);

      await tester.pumpFullScreen(controller);
      expect(controller.isFullScreen, isTrue);
      expect(swipeArea, findsNothing);

      // Same downward fling as the passing case, over the fullscreen video.
      await tester.fling(fullScreenBackground, const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(controller.isFullScreen, isTrue);
    });
  });

  group('ChewieController swipe options', () {
    test('default to an enabled gesture at 300 px/s', () {
      final controller = ChewieController(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse('https://example.com/video.mp4'),
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.swipeToExitFullscreen, isTrue);
      expect(controller.swipeThreshold, 300);
    });

    test('copyWith overrides both options', () {
      final controller = buildController();
      addTearDown(controller.dispose);

      final copy = controller.copyWith(
        swipeToExitFullscreen: false,
        swipeThreshold: 750,
      );
      addTearDown(copy.dispose);

      expect(copy.swipeToExitFullscreen, isFalse);
      expect(copy.swipeThreshold, 750);
    });

    test('copyWith preserves both options when they are omitted', () {
      final controller = buildController(
        swipeToExitFullscreen: false,
        swipeThreshold: 750,
      );
      addTearDown(controller.dispose);

      final copy = controller.copyWith();
      addTearDown(copy.dispose);

      expect(copy.swipeToExitFullscreen, isFalse);
      expect(copy.swipeThreshold, 750);
    });
  });
}
