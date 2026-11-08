import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'fake_video_player_platform.dart';

final _afterHideControlsTimer =
    ChewieController.defaultHideControlsTimer + const Duration(seconds: 1);

Finder get _sliderBox => find.ancestor(
  of: find.byType(Slider),
  matching: find.byType(AnimatedContainer),
);

Future<ChewieController> _pumpPlayer(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video.mp4'),
    ),
    autoPlay: false,
    customControls: const MaterialDesktopControls(),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Chewie(controller: controller)),
    ),
  );
  await tester.pump();
  return controller;
}

Future<void> _teardown(WidgetTester tester, ChewieController controller) async {
  await tester.pumpWidget(const SizedBox());
  unawaited(controller.videoPlayerController.dispose());
  await tester.pump();
  controller.dispose();
}

Future<TestGesture> _hover(WidgetTester tester, Offset location) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: location);
  addTearDown(gesture.removePointer);
  // The first move only reveals the (initially hidden) bar; the second one
  // lands on the now hit-testable volume control.
  await gesture.moveTo(location);
  await tester.pump();
  await gesture.moveTo(location + const Offset(1, 0));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return gesture;
}

bool _controlsVisible(WidgetTester tester) => !Provider.of<PlayerNotifier>(
  tester.element(find.byType(MaterialDesktopControls)),
  listen: false,
).hideStuff;

void main() {
  setUp(FakeVideoPlayerPlatform.install);

  testWidgets('volume slider is collapsed until the mute button is hovered', (
    tester,
  ) async {
    final controller = await _pumpPlayer(tester);

    expect(tester.getSize(_sliderBox).width, 0);

    await _hover(tester, tester.getCenter(find.byIcon(Icons.volume_up)));
    expect(tester.getSize(_sliderBox).width, greaterThan(0));

    await _teardown(tester, controller);
  });

  testWidgets('dragging the slider sets the volume; mute restores it', (
    tester,
  ) async {
    final controller = await _pumpPlayer(tester);
    final video = controller.videoPlayerController;
    await _hover(tester, tester.getCenter(find.byIcon(Icons.volume_up)));

    final slider = tester.getRect(find.byType(Slider));
    await tester.dragFrom(slider.center, Offset(-slider.width, 0));
    await tester.pump();
    expect(video.value.volume, 0);
    expect(find.byIcon(Icons.volume_off), findsOneWidget);

    // Unmuting brings back the level from before the drag, not the fallback.
    await tester.tap(find.byIcon(Icons.volume_off));
    await tester.pump();
    expect(video.value.volume, 1.0);

    // The track is inset by the slider's 8px horizontal padding.
    await tester.tapAt(
      Offset(slider.left + 8 + (slider.width - 16) * 0.3, slider.center.dy),
    );
    await tester.pump();
    expect(video.value.volume, closeTo(0.3, 0.05));
    expect(find.byIcon(Icons.volume_down), findsOneWidget);

    await _teardown(tester, controller);
  });

  testWidgets('controls stay up while the volume slider is hovered', (
    tester,
  ) async {
    final controller = await _pumpPlayer(tester);
    final gesture = await _hover(
      tester,
      tester.getCenter(find.byIcon(Icons.volume_up)),
    );

    await tester.pump(_afterHideControlsTimer);
    expect(_controlsVisible(tester), isTrue);

    // Leaving the volume control arms the hide timer again.
    await gesture.moveTo(tester.getCenter(find.byType(Chewie)));
    await tester.pump(_afterHideControlsTimer);
    expect(_controlsVisible(tester), isFalse);

    await _teardown(tester, controller);
  });

  testWidgets('the slider opens when it gets keyboard focus', (tester) async {
    final controller = await _pumpPlayer(tester);
    expect(tester.getSize(_sliderBox).width, 0);

    // Tab through the controls until the (still collapsed) slider has focus.
    bool sliderFocused() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<Slider>() !=
        null;
    for (var i = 0; i < 8 && !sliderFocused(); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(sliderFocused(), isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getSize(_sliderBox).width, greaterThan(0));

    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getSize(_sliderBox).width, 0);

    await _teardown(tester, controller);
  });
}
