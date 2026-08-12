import 'package:chewie/chewie.dart';
import 'package:chewie/src/progress_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

const _chapters = [
  ChewieChapter(title: 'Intro', start: Duration.zero),
  ChewieChapter(title: 'Second Chapter', start: Duration(minutes: 1)),
  ChewieChapter(title: 'Finale', start: Duration(minutes: 3)),
];

class _FakeVideoPlayerController extends VideoPlayerController {
  _FakeVideoPlayerController()
    : super.networkUrl(Uri.parse('https://example.com/video.m3u8')) {
    value = VideoPlayerValue(
      duration: const Duration(minutes: 4),
      isInitialized: true,
      position: const Duration(minutes: 2),
      buffered: [DurationRange(Duration.zero, const Duration(minutes: 3))],
    );
  }

  Duration? lastSeek;
  int playCalls = 0;
  int pauseCalls = 0;

  @override
  Future<void> seekTo(Duration position) async {
    lastSeek = position;
  }

  @override
  Future<void> play() async {
    playCalls++;
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> initialize() async {}
}

Widget _wrapBar(VideoProgressBar bar) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 400, height: 48, child: bar)),
    ),
  );
}

Future<TestGesture> _hoverAt(WidgetTester tester, Offset location) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(location);
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets('progress bar with chapters paints segments and handles hover', (
    tester,
  ) async {
    final controller = _FakeVideoPlayerController();
    await tester.pumpWidget(
      _wrapBar(
        VideoProgressBar(
          controller,
          barHeight: 10,
          handleHeight: 6,
          drawShadow: true,
          chapters: _chapters,
        ),
      ),
    );

    expect(find.byType(VideoProgressBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    final barCenter = tester.getCenter(find.byType(VideoProgressBar));
    final gesture = await _hoverAt(tester, barCenter);
    await tester.pump();

    expect(find.textContaining('Second Chapter'), findsOneWidget);

    await gesture.moveTo(barCenter - const Offset(150, 0));
    await tester.pump();
    expect(find.textContaining('Intro'), findsOneWidget);

    await gesture.moveTo(barCenter + const Offset(180, 0));
    await tester.pump();
    expect(find.textContaining('Finale'), findsOneWidget);

    await gesture.moveTo(const Offset(1, 1));
    await tester.pump();
    expect(find.textContaining('Finale'), findsNothing);
  });

  testWidgets('scrubbing shows the pointed chapter and seeks on release', (
    tester,
  ) async {
    final controller = _FakeVideoPlayerController();
    await tester.pumpWidget(
      _wrapBar(
        VideoProgressBar(
          controller,
          barHeight: 10,
          handleHeight: 6,
          drawShadow: true,
          chapters: _chapters,
        ),
      ),
    );

    final barCenter = tester.getCenter(find.byType(VideoProgressBar));
    final drag = await tester.startGesture(barCenter);
    await drag.moveBy(const Offset(60, 0));
    await tester.pump();
    await drag.moveBy(const Offset(60, 0));
    await tester.pump();

    expect(find.textContaining('Finale'), findsOneWidget);

    await drag.up();
    await tester.pump();

    expect(controller.lastSeek, isNotNull);
    expect(controller.lastSeek!, greaterThan(const Duration(minutes: 3)));
  });

  testWidgets('tap seeks to the tapped position', (tester) async {
    final controller = _FakeVideoPlayerController();
    await tester.pumpWidget(
      _wrapBar(
        VideoProgressBar(
          controller,
          barHeight: 10,
          handleHeight: 6,
          drawShadow: true,
          chapters: _chapters,
        ),
      ),
    );

    await tester.tapAt(tester.getCenter(find.byType(VideoProgressBar)));
    await tester.pump();

    expect(controller.lastSeek, const Duration(minutes: 2));
  });

  testWidgets('out-of-range chapter starts are ignored when painting', (
    tester,
  ) async {
    final controller = _FakeVideoPlayerController();
    await tester.pumpWidget(
      _wrapBar(
        VideoProgressBar(
          controller,
          barHeight: 10,
          handleHeight: 6,
          drawShadow: true,
          chapters: const [
            ChewieChapter(title: 'Intro', start: Duration.zero),
            ChewieChapter(title: 'Beyond', start: Duration(minutes: 10)),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('no chapter label is shown without chapters', (tester) async {
    final controller = _FakeVideoPlayerController();
    await tester.pumpWidget(
      _wrapBar(
        VideoProgressBar(
          controller,
          barHeight: 10,
          handleHeight: 6,
          drawShadow: true,
        ),
      ),
    );

    final region = tester.widget<MouseRegion>(
      find
          .descendant(
            of: find.byType(VideoProgressBar),
            matching: find.byType(MouseRegion),
          )
          .first,
    );
    expect(region.cursor, SystemMouseCursors.click);

    await _hoverAt(tester, tester.getCenter(find.byType(VideoProgressBar)));
    await tester.pump();
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('non-draggable bar with chapters never seeks', (tester) async {
    final controller = _FakeVideoPlayerController();
    await tester.pumpWidget(
      _wrapBar(
        VideoProgressBar(
          controller,
          barHeight: 10,
          handleHeight: 6,
          drawShadow: true,
          draggableProgressBar: false,
          chapters: _chapters,
        ),
      ),
    );

    await tester.tapAt(tester.getCenter(find.byType(VideoProgressBar)));
    await tester.pump();

    expect(controller.lastSeek, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uninitialized controller paints the plain background bar', (
    tester,
  ) async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video.m3u8'),
    );
    await tester.pumpWidget(
      _wrapBar(
        VideoProgressBar(
          controller,
          barHeight: 10,
          handleHeight: 6,
          drawShadow: true,
          chapters: _chapters,
        ),
      ),
    );

    await _hoverAt(tester, tester.getCenter(find.byType(VideoProgressBar)));
    await tester.pump();

    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('ChewieChapter holds its title and start time', () {
    const chapter = ChewieChapter(title: 'Intro', start: Duration(seconds: 5));
    expect(chapter.title, 'Intro');
    expect(chapter.start, const Duration(seconds: 5));
  });

  test('ChewieController rejects chapters not sorted by start time', () {
    expect(
      () => ChewieController(
        videoPlayerController: _FakeVideoPlayerController(),
        chapters: const [
          ChewieChapter(title: 'Second', start: Duration(minutes: 1)),
          ChewieChapter(title: 'First', start: Duration.zero),
        ],
      ),
      throwsAssertionError,
    );
  });

  test('ChewieController exposes chapters and copyWith carries them over', () {
    final controller = ChewieController(
      videoPlayerController: _FakeVideoPlayerController(),
      chapters: _chapters,
    );
    expect(controller.chapters, _chapters);

    final unchanged = controller.copyWith();
    expect(unchanged.chapters, _chapters);

    const replacement = [ChewieChapter(title: 'Only', start: Duration.zero)];
    final replaced = controller.copyWith(chapters: replacement);
    expect(replaced.chapters, replacement);
  });

  for (final (String name, Widget controls) in [
    ('MaterialControls', const MaterialControls()),
    ('MaterialDesktopControls', const MaterialDesktopControls()),
    (
      'CupertinoControls',
      const CupertinoControls(
        backgroundColor: Colors.black,
        iconColor: Colors.white,
      ),
    ),
  ]) {
    testWidgets('$name forwards chapters to its progress bar', (tester) async {
      final chewieController = ChewieController(
        videoPlayerController: _FakeVideoPlayerController(),
        chapters: _chapters,
        customControls: controls,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Chewie(controller: chewieController)),
        ),
      );
      await tester.pump();

      final bar = tester.widget<VideoProgressBar>(
        find.byType(VideoProgressBar),
      );
      expect(bar.chapters, _chapters);

      await tester.pumpWidget(const SizedBox());
    });
  }
}
