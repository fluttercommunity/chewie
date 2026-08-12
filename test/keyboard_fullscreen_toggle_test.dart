import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

const _src =
    'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4';

ChewieController _controller({bool allowFullScreen = true}) {
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(Uri.parse(_src)),
    autoPlay: false,
    looping: false,
    allowFullScreen: allowFullScreen,
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

Future<void> _pressF(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('F key toggles fullscreen on and off', (tester) async {
    final controller = _controller();
    await _pumpPlayer(tester, controller);
    expect(controller.isFullScreen, isFalse);

    await _pressF(tester);
    expect(controller.isFullScreen, isTrue);

    await _pressF(tester);
    expect(controller.isFullScreen, isFalse);
  });

  testWidgets('F key does nothing when allowFullScreen is false', (
    tester,
  ) async {
    final controller = _controller(allowFullScreen: false);
    await _pumpPlayer(tester, controller);

    await _pressF(tester);
    expect(controller.isFullScreen, isFalse);
  });
}
