import 'package:chewie/chewie.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

const _src =
    'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4';

ChewieController _controller() {
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(Uri.parse(_src)),
    autoPlay: false,
    looping: false,
    customControls: const MaterialDesktopControls(),
  );
}

Finder _hiddenCursor() => find.byWidgetPredicate(
  (w) => w is MouseRegion && w.cursor == SystemMouseCursors.none,
);

void main() {
  testWidgets(
    'cursor is never hidden while not in fullscreen, even when idle',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Chewie(controller: _controller())),
        ),
      );
      await tester.pump();

      // Drive a mouse hover so the controls arm their auto-hide timer, then let
      // the player go idle (controls hidden).
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(find.byType(Chewie)));
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(Chewie)));
      await tester.pump(const Duration(seconds: 4));

      // Idle outside fullscreen must not hide the cursor.
      expect(_hiddenCursor(), findsNothing);
    },
  );

  test('hideCursorInFullScreen defaults to true and survives copyWith', () {
    final controller = ChewieController(
      videoPlayerController: VideoPlayerController.networkUrl(Uri.parse(_src)),
    );
    expect(controller.hideCursorInFullScreen, isTrue);
    expect(
      controller.copyWith(hideCursorInFullScreen: false).hideCursorInFullScreen,
      isFalse,
    );
  });
}
