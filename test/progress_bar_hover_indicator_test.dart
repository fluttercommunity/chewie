import 'package:chewie/src/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

class _FakeVideoPlayerController extends Fake
    with ChangeNotifier
    implements VideoPlayerController {
  @override
  VideoPlayerValue value = const VideoPlayerValue(
    duration: Duration(minutes: 4),
    isInitialized: true,
  );

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> dispose() async {
    super.dispose();
  }
}

void main() {
  testWidgets('scrub time indicator escapes ancestor clips (iOS bottom bar)', (
    WidgetTester tester,
  ) async {
    final controller = _FakeVideoPlayerController();

    // Mimics the cupertino bottom bar: a short, clipped strip. Before the
    // overlay-based indicator, the pill was cut off by this ClipRRect.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: SizedBox(
                width: 300,
                height: 30,
                child: VideoProgressBar(
                  controller,
                  barHeight: 5,
                  handleHeight: 6,
                  drawShadow: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final barRect = tester.getRect(find.byType(VideoProgressBar));

    // Scrub with a touch drag, like on iOS.
    final gesture = await tester.startGesture(barRect.center);
    // The first move settles the gesture arena (touch slop); the second
    // one delivers a drag update.
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();

    final pill = find.textContaining(':');
    expect(pill, findsOneWidget);

    // The pill must not be painted inside the clipping bar. OverlayPortal
    // keeps the overlay child in the element tree but reparents its render
    // object into the Overlay, so check the render-object ancestry.
    final RenderObject clipRender = tester.renderObject(find.byType(ClipRRect));
    RenderObject? node = tester.renderObject(pill);
    while (node != null) {
      expect(node, isNot(same(clipRender)));
      node = node.parent;
    }

    // It sits fully above the painted bar, outside the clipped strip.
    final pillRect = tester.getRect(pill);
    expect(pillRect.bottom, lessThan(barRect.top));

    // And it stays horizontally glued to the pointer position.
    expect(
      pillRect.center.dx,
      moreOrLessEquals(barRect.center.dx + 30, epsilon: 1.0),
    );

    await gesture.up();
    await tester.pump();

    // Released: the indicator goes away.
    expect(find.textContaining(':'), findsNothing);
  });
}
