import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart'
    as platform_interface;

import 'fake_video_player_platform.dart';

const String _srcA = 'https://example.com/a.m3u8';
const String _srcB = 'https://example.com/b.m3u8';

List<platform_interface.VideoAudioTrack> _platformTracks({
  String selected = 'en-id',
}) => [
  platform_interface.VideoAudioTrack(
    id: 'en-id',
    label: 'English',
    language: 'en',
    isSelected: selected == 'en-id',
  ),
  platform_interface.VideoAudioTrack(
    id: 'fr-id',
    label: null,
    language: 'fr',
    isSelected: selected == 'fr-id',
  ),
  platform_interface.VideoAudioTrack(
    id: 'x-id',
    label: '',
    language: null,
    isSelected: selected == 'x-id',
  ),
];

const _hostTracks = <AudioTrack>[
  AudioTrack(id: 'h0', label: 'Host one'),
  AudioTrack(id: 'h1', label: 'Host two'),
];

VideoPlayerController _network(String src) =>
    VideoPlayerController.networkUrl(Uri.parse(src));

/// Lets the reads Chewie started off a player notification finish.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

Future<void> _driveFrame() async {
  final binding = TestWidgetsFlutterBinding.instance;
  binding.handleBeginFrame(Duration.zero);
  binding.handleDrawFrame();
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVideoPlayerPlatform platform;

  setUp(() {
    platform = FakeVideoPlayerPlatform.install()
      ..audioTrackSupport = true
      ..audioTracks = _platformTracks();
  });

  group('detected audio tracks', () {
    test('are listed once the video is initialized', () async {
      final vpc = _network(_srcA);
      final controller = ChewieController(videoPlayerController: vpc);
      var notified = 0;
      controller.addListener(() => notified++);

      expect(controller.audioTracks, isEmpty);
      expect(platform.audioTrackReads, 0);

      await vpc.initialize();
      await _settle();

      expect(controller.audioTracks, const [
        AudioTrack(id: 'en-id', label: 'English', language: 'en'),
        AudioTrack(id: 'fr-id', label: 'fr', language: 'fr'),
        AudioTrack(id: 'x-id', label: 'x-id'),
      ]);
      expect(controller.activeAudioTrackId, 'en-id');
      expect(controller.hasAudioTracks, isTrue);
      expect(notified, 1);

      await vpc.dispose();
      controller.dispose();
    });

    test('are read again once playback first starts', () async {
      platform.audioTracksNeedPlayback = true;
      final vpc = _network(_srcA);
      final controller = ChewieController(videoPlayerController: vpc);

      await vpc.initialize();
      await _settle();
      expect(controller.audioTracks, isEmpty);
      expect(platform.audioTrackReads, 1);

      await vpc.play();
      await _settle();
      expect(controller.audioTracks, hasLength(3));
      expect(controller.activeAudioTrackId, 'en-id');
      expect(platform.audioTrackReads, 2);

      // Only once: later notifications do not poll the platform.
      await vpc.seekTo(const Duration(seconds: 5));
      await vpc.pause();
      await vpc.play();
      await _settle();
      expect(platform.audioTrackReads, 2);

      await vpc.dispose();
      controller.dispose();
    });

    test('selecting one switches the video player', () async {
      final vpc = _network(_srcA);
      final controller = ChewieController(videoPlayerController: vpc);
      await vpc.initialize();
      await _settle();

      controller.selectAudioTrack(controller.audioTracks[1]);
      await _settle();

      expect(controller.activeAudioTrackId, 'fr-id');
      expect(platform.audioTrackSelections, [
        (platform.playerIdFor(_srcA), 'fr-id'),
      ]);

      await vpc.dispose();
      controller.dispose();
    });

    test('a failed switch falls back to what the player reports', () async {
      final vpc = _network(_srcA);
      final controller = ChewieController(videoPlayerController: vpc);
      await vpc.initialize();
      await _settle();

      platform.audioTrackError = StateError('no such track');
      controller.selectAudioTrack(controller.audioTracks[1]);
      platform.audioTrackError = null;
      await _settle();
      await _settle();

      expect(platform.audioTrackSelections, isEmpty);
      expect(controller.activeAudioTrackId, 'en-id');

      await vpc.dispose();
      controller.dispose();
    });

    test('preferredLanguages picks the track that plays first', () async {
      final vpc = _network(_srcA);
      final controller = ChewieController(
        videoPlayerController: vpc,
        preferredLanguages: const ['de', 'fr-CA'],
      );
      await vpc.initialize();
      await _settle();

      expect(controller.activeAudioTrackId, 'fr-id');
      expect(platform.audioTrackSelections.single.$2, 'fr-id');

      await vpc.dispose();
      controller.dispose();
    });

    test('preferredLanguages leaves a matching default alone', () async {
      final vpc = _network(_srcA);
      final controller = ChewieController(
        videoPlayerController: vpc,
        preferredLanguages: const ['en'],
      );
      await vpc.initialize();
      await _settle();

      expect(controller.activeAudioTrackId, 'en-id');
      expect(platform.audioTrackSelections, isEmpty);

      await vpc.dispose();
      controller.dispose();
    });

    test('survive swapVideoSource and keep the chosen language', () async {
      final oldVpc = _network(_srcA);
      await oldVpc.initialize();
      final controller = ChewieController(videoPlayerController: oldVpc);
      await _settle();
      controller.selectAudioTrack(controller.audioTracks[1]);
      await _settle();

      // The new player starts on its own default again.
      platform.audioTracks = _platformTracks();
      final newVpc = _network(_srcB);
      await controller.swapVideoSource(newVpc);
      await _settle();

      expect(controller.audioTracks, hasLength(3));
      expect(controller.activeAudioTrackId, 'fr-id');
      expect(platform.audioTrackSelections, [
        (platform.playerIdFor(_srcA), 'fr-id'),
        (platform.playerIdFor(_srcB), 'fr-id'),
      ]);

      controller.selectAudioTrack(controller.audioTracks[0]);
      await _settle();
      expect(platform.audioTrackSelections.last, (
        platform.playerIdFor(_srcB),
        'en-id',
      ));

      await _driveFrame();
      await newVpc.dispose();
      controller.dispose();
    });

    test('are not inherited as host tracks by copyWith', () async {
      final vpc = _network(_srcA);
      final controller = ChewieController(videoPlayerController: vpc);
      await vpc.initialize();
      await _settle();
      expect(controller.audioTracks, hasLength(3));

      final copy = controller.copyWith(showControls: false);
      await _settle();
      copy.selectAudioTrack(copy.audioTracks[1]);
      await _settle();

      expect(copy.audioTracks, hasLength(3));
      expect(platform.audioTrackSelections.single.$2, 'fr-id');

      await vpc.dispose();
      controller.dispose();
      copy.dispose();
    });
  });

  group('nothing automatic happens', () {
    Future<void> expectUntouched(
      ChewieController controller, {
      required List<AudioTrack> tracks,
    }) async {
      final vpc = controller.videoPlayerController;
      await vpc.initialize();
      await vpc.play();
      await _settle();

      expect(controller.audioTracks, tracks);
      expect(platform.audioTrackReads, 0);
      if (tracks.isNotEmpty) {
        controller.selectAudioTrack(tracks.last);
        await _settle();
        expect(controller.activeAudioTrackId, tracks.last.id);
      }
      expect(platform.audioTrackSelections, isEmpty);

      await vpc.dispose();
      controller.dispose();
    }

    test('when the host supplies audioTracks', () async {
      await expectUntouched(
        ChewieController(
          videoPlayerController: _network(_srcA),
          audioTracks: _hostTracks,
          activeAudioTrackId: 'h0',
        ),
        tracks: _hostTracks,
      );
    });

    test('when the host supplies onAudioTrackChanged', () async {
      await expectUntouched(
        ChewieController(
          videoPlayerController: _network(_srcA),
          onAudioTrackChanged: (_) {},
        ),
        tracks: const [],
      );
    });

    test('when autoDetectAudioTracks is off', () async {
      await expectUntouched(
        ChewieController(
          videoPlayerController: _network(_srcA),
          autoDetectAudioTracks: false,
        ),
        tracks: const [],
      );
    });

    test('once the host calls setAudioTracks', () async {
      final vpc = _network(_srcA);
      final controller = ChewieController(videoPlayerController: vpc);
      await vpc.initialize();
      await _settle();
      expect(controller.audioTracks, hasLength(3));

      controller.setAudioTracks(_hostTracks);
      await vpc.play();
      await _settle();
      controller.selectAudioTrack(_hostTracks[1]);
      await _settle();

      expect(controller.audioTracks, _hostTracks);
      expect(controller.activeAudioTrackId, 'h1');
      expect(platform.audioTrackReads, 1);
      expect(platform.audioTrackSelections, isEmpty);

      await vpc.dispose();
      controller.dispose();
    });

    test('when the platform reports no support', () async {
      platform.audioTrackSupport = false;
      final vpc = _network(_srcA);
      final controller = ChewieController(videoPlayerController: vpc);
      await vpc.initialize();
      await vpc.play();
      await _settle();

      expect(controller.audioTracks, isEmpty);
      expect(controller.hasAudioTracks, isFalse);
      expect(platform.audioTrackReads, 0);

      await vpc.dispose();
      controller.dispose();
    });

    test('when the platform throws UnimplementedError', () async {
      platform.audioTrackError = UnimplementedError('getAudioTracks()');
      final vpc = _network(_srcA);
      final controller = ChewieController(videoPlayerController: vpc);
      await vpc.initialize();
      await vpc.play();
      await _settle();

      expect(controller.audioTracks, isEmpty);
      expect(controller.hasAudioTracks, isFalse);

      await vpc.dispose();
      controller.dispose();
    });

    test('when the player has a single track', () async {
      platform.audioTracks = [_platformTracks().first];
      final vpc = _network(_srcA);
      final controller = ChewieController(videoPlayerController: vpc);
      await vpc.initialize();
      await _settle();

      expect(controller.hasAudioTracks, isFalse);

      await vpc.dispose();
      controller.dispose();
    });
  });

  group('controls', () {
    Future<ChewieController> pump(
      WidgetTester tester,
      TargetPlatform targetPlatform,
    ) async {
      final controller = ChewieController(
        videoPlayerController: _network(_srcA),
        autoInitialize: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: targetPlatform),
          home: Scaffold(body: Chewie(controller: controller)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      return controller;
    }

    Future<void> teardown(
      WidgetTester tester,
      ChewieController controller,
    ) async {
      await tester.pumpWidget(const SizedBox());
      unawaited(controller.videoPlayerController.dispose());
      await tester.pump();
      controller.dispose();
    }

    for (final targetPlatform in [TargetPlatform.android, TargetPlatform.iOS]) {
      testWidgets('$targetPlatform: the Audio menu lists and switches the '
          'detected tracks', (tester) async {
        final controller = await pump(tester, targetPlatform);

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Audio'));
        await tester.pumpAndSettle();
        expect(find.text('English'), findsOneWidget);

        // Material repeats the language as a hint under the label.
        await tester.tap(find.text('fr').first);
        await tester.pumpAndSettle();

        expect(controller.activeAudioTrackId, 'fr-id');
        expect(platform.audioTrackSelections.single.$2, 'fr-id');

        await teardown(tester, controller);
      });

      testWidgets('$targetPlatform: no Audio entry when the player has no '
          'tracks', (tester) async {
        platform.audioTracks = [];
        final controller = await pump(tester, targetPlatform);

        final options = find.byIcon(Icons.more_vert);
        if (options.evaluate().isNotEmpty) {
          await tester.tap(options);
          await tester.pumpAndSettle();
        }
        expect(find.text('Audio'), findsNothing);

        await teardown(tester, controller);
      });
    }
  });
}
