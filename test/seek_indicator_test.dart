import 'package:chewie/chewie.dart';
import 'package:chewie/src/seek_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

const _src =
    'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4';

ChewieController _controller({bool showSeekIndicator = true}) {
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(Uri.parse(_src)),
    autoPlay: false,
    looping: false,
    showSeekIndicator: showSeekIndicator,
    customControls: const MaterialDesktopControls(),
  );
}

Future<void> _pumpPlayer(
  WidgetTester tester,
  ChewieController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Chewie(controller: controller)),
    ),
  );
  await tester.pump();
}

SeekIndicator _indicator(WidgetTester tester) =>
    tester.widget<SeekIndicator>(find.byType(SeekIndicator));

void main() {
  testWidgets('accumulates seconds on repeated forward keypresses', (
    tester,
  ) async {
    await _pumpPlayer(tester, _controller());

    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
    }

    final indicator = _indicator(tester);
    expect(indicator.show, isTrue);
    expect(indicator.forward, isTrue);
    expect(indicator.seconds, 30);
  });

  testWidgets('resets and flips direction on an opposite keypress', (
    tester,
  ) async {
    await _pumpPlayer(tester, _controller());

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    final indicator = _indicator(tester);
    expect(indicator.forward, isFalse);
    expect(indicator.seconds, 10);
  });

  testWidgets('fades out shortly after the last keypress', (tester) async {
    await _pumpPlayer(tester, _controller());

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_indicator(tester).show, isTrue);

    await tester.pump(const Duration(seconds: 1));
    expect(_indicator(tester).show, isFalse);
  });

  testWidgets('is not built when showSeekIndicator is false', (tester) async {
    await _pumpPlayer(tester, _controller(showSeekIndicator: false));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(find.byType(SeekIndicator), findsNothing);
  });

  test('showSeekIndicator defaults to true and survives copyWith', () {
    final controller = ChewieController(
      videoPlayerController: VideoPlayerController.networkUrl(Uri.parse(_src)),
    );
    expect(controller.showSeekIndicator, isTrue);
    expect(
      controller.copyWith(showSeekIndicator: false).showSeekIndicator,
      isFalse,
    );
  });
}
