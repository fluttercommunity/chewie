import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import 'fake_video_player_platform.dart';

final Uri _src = Uri.parse('https://example.com/video.mp4');

const _qualities = <VideoQuality>[
  VideoQuality(id: '480', label: '480p'),
  VideoQuality(id: '1080', label: '1080p'),
];

ChewieController _controller({
  List<VideoQuality> qualities = const <VideoQuality>[],
  Object? activeVideoQualityId,
  void Function(VideoQuality)? onVideoQualityChanged,
  OptionsTranslation? optionsTranslation,
  Widget? customControls,
}) {
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(_src),
    autoPlay: false,
    looping: false,
    videoQualities: qualities,
    activeVideoQualityId: activeVideoQualityId,
    onVideoQualityChanged: onVideoQualityChanged,
    optionsTranslation: optionsTranslation,
    customControls: customControls,
  );
}

Future<void> _openOptionsMenu(WidgetTester tester) async {
  await tester.tap(find.byType(Chewie));
  await tester.pump();
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FakeVideoPlayerPlatform.install();
  });

  group('ChewieController video qualities', () {
    test('hasVideoQualities requires more than one entry', () {
      expect(_controller().hasVideoQualities, isFalse);
      expect(
        _controller(qualities: [_qualities.first]).hasVideoQualities,
        isFalse,
      );
      expect(_controller(qualities: _qualities).hasVideoQualities, isTrue);
    });

    test('setVideoQualities replaces the list and notifies', () {
      final controller = _controller();
      var notified = 0;
      controller.addListener(() => notified++);

      controller.setVideoQualities(_qualities);

      expect(controller.videoQualities, _qualities);
      expect(controller.hasVideoQualities, isTrue);
      expect(notified, 1);
    });

    test('selectVideoQuality sets the active id and notifies the host', () {
      VideoQuality? received;
      var called = 0;
      var notified = 0;
      final controller = _controller(
        qualities: _qualities,
        onVideoQualityChanged: (quality) {
          received = quality;
          called++;
        },
      );
      controller.addListener(() => notified++);

      controller.selectVideoQuality(_qualities[1]);

      expect(controller.activeVideoQualityId, '1080');
      expect(called, 1);
      expect(received, _qualities[1]);
      expect(notified, 1);
    });

    test('copyWith carries the quality configuration over', () {
      void onChanged(VideoQuality _) {}
      final controller = _controller(
        qualities: _qualities,
        activeVideoQualityId: '480',
        onVideoQualityChanged: onChanged,
      );

      final copy = controller.copyWith();

      expect(copy.videoQualities, _qualities);
      expect(copy.activeVideoQualityId, '480');
      expect(copy.onVideoQualityChanged, same(onChanged));
    });
  });

  group('video quality menu (Material)', () {
    testWidgets('is hidden without at least two qualities', (tester) async {
      final controller = _controller(
        qualities: [_qualities.first],
        customControls: const MaterialControls(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Chewie(controller: controller)),
        ),
      );

      await _openOptionsMenu(tester);

      expect(find.text('Quality'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      unawaited(controller.videoPlayerController.dispose());
      await tester.pump();
      controller.dispose();
    });

    testWidgets('lists qualities, marks the active one and notifies the host', (
      tester,
    ) async {
      VideoQuality? chosen;
      final controller = _controller(
        qualities: _qualities,
        activeVideoQualityId: '480',
        onVideoQualityChanged: (quality) => chosen = quality,
        customControls: const MaterialControls(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Chewie(controller: controller)),
        ),
      );

      await _openOptionsMenu(tester);
      await tester.tap(find.text('Quality'));
      await tester.pumpAndSettle();

      expect(find.text('480p'), findsOneWidget);
      expect(find.text('1080p'), findsOneWidget);
      final activeRow = find.ancestor(
        of: find.text('480p'),
        matching: find.byType(ListTile),
      );
      expect(
        tester.widget<ListTile>(activeRow).selected,
        isTrue,
        reason: 'the active quality row is marked as selected',
      );

      await tester.tap(find.text('1080p'));
      await tester.pumpAndSettle();

      expect(chosen, _qualities[1]);
      expect(controller.activeVideoQualityId, '1080');

      await tester.pumpWidget(const SizedBox());
      unawaited(controller.videoPlayerController.dispose());
      await tester.pump();
      controller.dispose();
    });

    testWidgets('uses the translated button text', (tester) async {
      final controller = _controller(
        qualities: _qualities,
        optionsTranslation: OptionsTranslation(qualityButtonText: 'Qualité'),
        customControls: const MaterialControls(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Chewie(controller: controller)),
        ),
      );

      await _openOptionsMenu(tester);

      expect(find.text('Qualité'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      unawaited(controller.videoPlayerController.dispose());
      await tester.pump();
      controller.dispose();
    });
  });
}
