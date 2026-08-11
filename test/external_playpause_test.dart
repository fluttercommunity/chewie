import 'package:chewie/chewie.dart';
import 'package:chewie/src/center_play_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

const _src =
    'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4';

// Long enough for the hide timer started by _cancelAndRestartTimer to fire.
final _afterHideControlsTimer =
    ChewieController.defaultHideControlsTimer + const Duration(seconds: 1);

/// Flips the playing state the way an external actor would (hardware media
/// keys handled by the browser, MediaSession, the embedder driving the
/// controller): the value changes without going through the controls' own
/// play/pause path.
void _setPlayingExternally(
  VideoPlayerController controller, {
  required bool playing,
}) {
  controller.value = controller.value.copyWith(isPlaying: playing);
}

ChewieController _chewieController(VideoPlayerController videoController) {
  return ChewieController(
    videoPlayerController: videoController,
    autoPlay: false,
    looping: false,
    showControlsOnInitialize: false,
    customControls: const MaterialDesktopControls(),
  );
}

Future<VideoPlayerController> _pumpPlayer(WidgetTester tester) async {
  final videoController = VideoPlayerController.networkUrl(Uri.parse(_src));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Chewie(controller: _chewieController(videoController)),
      ),
    ),
  );
  await tester.pump();
  return videoController;
}

bool _controlsVisible(WidgetTester tester) =>
    tester.widget<CenterPlayButton>(find.byType(CenterPlayButton)).show;

void main() {
  testWidgets('reveals the controls and auto-hides on an external play', (
    tester,
  ) async {
    final videoController = await _pumpPlayer(tester);
    expect(_controlsVisible(tester), isFalse);

    _setPlayingExternally(videoController, playing: true);
    await tester.pump();
    expect(_controlsVisible(tester), isTrue);

    await tester.pump(_afterHideControlsTimer);
    expect(_controlsVisible(tester), isFalse);
  });

  testWidgets('reveals the controls and keeps them up on an external pause', (
    tester,
  ) async {
    final videoController = await _pumpPlayer(tester);

    _setPlayingExternally(videoController, playing: true);
    await tester.pump();
    await tester.pump(_afterHideControlsTimer);
    expect(_controlsVisible(tester), isFalse);

    _setPlayingExternally(videoController, playing: false);
    await tester.pump();
    expect(_controlsVisible(tester), isTrue);

    await tester.pump(_afterHideControlsTimer);
    expect(
      _controlsVisible(tester),
      isTrue,
      reason: 'a paused video keeps its controls up, as when paused from them',
    );
  });

  testWidgets('keeps the controls up after a pause from the controls', (
    tester,
  ) async {
    final videoController = await _pumpPlayer(tester);

    _setPlayingExternally(videoController, playing: true);
    await tester.pump();
    await tester.pump(_afterHideControlsTimer);
    expect(_controlsVisible(tester), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(videoController.value.isPlaying, isFalse);
    expect(_controlsVisible(tester), isTrue);

    await tester.pump(_afterHideControlsTimer);
    expect(_controlsVisible(tester), isTrue);
  });

  testWidgets('leaves hidden controls hidden when only the position changes', (
    tester,
  ) async {
    final videoController = await _pumpPlayer(tester);

    _setPlayingExternally(videoController, playing: true);
    await tester.pump();
    await tester.pump(_afterHideControlsTimer);
    expect(_controlsVisible(tester), isFalse);

    videoController.value = videoController.value.copyWith(
      position: const Duration(seconds: 42),
    );
    await tester.pump();
    expect(_controlsVisible(tester), isFalse);
  });
}
