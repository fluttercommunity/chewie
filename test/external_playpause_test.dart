import 'package:chewie/chewie.dart';
import 'package:chewie/src/center_play_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

const _src =
    'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4';

/// Lets tests flip the playing state the way an external actor would
/// (hardware media keys handled by the browser, MediaSession): the value
/// changes without going through the controls' own play/pause path.
class _FakeVideoPlayerController extends VideoPlayerController {
  _FakeVideoPlayerController() : super.networkUrl(Uri.parse(_src));

  void setPlaying(bool playing) {
    value = value.copyWith(isPlaying: playing);
  }

  void setPosition(Duration position) {
    value = value.copyWith(position: position);
  }
}

ChewieController _controller(_FakeVideoPlayerController videoController) {
  return ChewieController(
    videoPlayerController: videoController,
    autoPlay: false,
    looping: false,
    showControlsOnInitialize: false,
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

bool _controlsVisible(WidgetTester tester) =>
    tester.widget<CenterPlayButton>(find.byType(CenterPlayButton)).show;

void main() {
  testWidgets('reveals the controls and auto-hides on an external play', (
    tester,
  ) async {
    final videoController = _FakeVideoPlayerController();
    await _pumpPlayer(tester, _controller(videoController));
    expect(_controlsVisible(tester), isFalse);

    videoController.setPlaying(true);
    await tester.pump();
    expect(_controlsVisible(tester), isTrue);

    await tester.pump(const Duration(seconds: 4));
    expect(_controlsVisible(tester), isFalse);
  });

  testWidgets('reveals the controls and auto-hides on an external pause', (
    tester,
  ) async {
    final videoController = _FakeVideoPlayerController();
    await _pumpPlayer(tester, _controller(videoController));

    videoController.setPlaying(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(_controlsVisible(tester), isFalse);

    videoController.setPlaying(false);
    await tester.pump();
    expect(_controlsVisible(tester), isTrue);

    await tester.pump(const Duration(seconds: 4));
    expect(_controlsVisible(tester), isFalse);
  });

  testWidgets('leaves hidden controls hidden when only the position changes', (
    tester,
  ) async {
    final videoController = _FakeVideoPlayerController();
    await _pumpPlayer(tester, _controller(videoController));

    videoController.setPlaying(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(_controlsVisible(tester), isFalse);

    videoController.setPosition(const Duration(seconds: 42));
    await tester.pump();
    expect(_controlsVisible(tester), isFalse);
  });
}
