import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import 'fake_cast_controller.dart';
import 'fake_video_player_platform.dart';

const _vtt = '''
WEBVTT
Kind: captions

NOTE a comment
that spans lines

1
00:00:01.000 --> 00:00:04.000 align:center
<i>Hello</i>

intro
00:03.500 --> 00:00:06.000
Overlapping line
second line

00:00:10.000 --> 00:00:12.000
''';

const _srt =
    '1\r\n00:00:01,000 --> 00:00:02,500\r\nBonjour\r\n\r\n'
    '2\r\n01:00:00,000 --> 01:00:01,000\r\n<b>Fin</b>\r\n';

List<Subtitle> _cues(String text, {int startSeconds = 0}) => [
  Subtitle(
    index: 0,
    start: Duration(seconds: startSeconds),
    end: Duration(seconds: startSeconds + 10),
    text: text,
  ),
];

VideoPlayerController _network() =>
    VideoPlayerController.networkUrl(Uri.parse('https://example.com/v.m3u8'));

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseSubtitles', () {
    test('reads WebVTT, skipping headers, notes, ids and settings', () {
      final cues = parseSubtitles(_vtt);
      expect(cues, hasLength(2));
      expect(cues[0].start, const Duration(seconds: 1));
      expect(cues[0].end, const Duration(seconds: 4));
      expect(cues[0].text, '<i>Hello</i>');
      expect(cues[1].start, const Duration(milliseconds: 3500));
      expect(cues[1].text, 'Overlapping line\nsecond line');
      expect(cues.map((cue) => cue.index), [0, 1]);
    });

    test('reads SubRip with CRLF line endings and a BOM', () {
      final cues = parseSubtitles('﻿$_srt');
      expect(cues, hasLength(2));
      expect(cues[0].end, const Duration(milliseconds: 2500));
      expect(cues[0].text, 'Bonjour');
      expect(cues[1].start, const Duration(hours: 1));
      expect(cues[1].text, '<b>Fin</b>');
    });

    test('skips STYLE and REGION blocks and keeps arrows in cue text', () {
      final cues = parseSubtitles('''
WEBVTT

STYLE
::cue { color: yellow }

REGION
id:fred width:40%

00:01.000 --> 00:02.000
Left --> right
''');
      expect(cues.single.text, 'Left --> right');
      expect(cues.single.start, const Duration(seconds: 1));
    });

    test('returns nothing for text without cues', () {
      expect(parseSubtitles(''), isEmpty);
      expect(parseSubtitles('<html>Not found</html>'), isEmpty);
    });
  });

  group('SubtitleTrack', () {
    test('hasSource is true with a url or a loader', () {
      expect(const SubtitleTrack(id: 0, label: 'a').hasSource, isFalse);
      expect(
        SubtitleTrack(id: 0, label: 'a', url: Uri.parse('x.vtt')).hasSource,
        isTrue,
      );
      expect(
        SubtitleTrack(id: 0, label: 'a', loader: () async => []).hasSource,
        isTrue,
      );
    });
  });

  group('tracks with a source', () {
    late FakeVideoPlayerPlatform platform;
    late VideoPlayerController vpc;

    setUp(() async {
      platform = FakeVideoPlayerPlatform.install();
      vpc = _network();
      await vpc.initialize();
    });

    tearDown(() => vpc.dispose());

    test('load lazily, once per track, and follow the position', () async {
      var loads = 0;
      final track = SubtitleTrack(
        id: 'en',
        label: 'English',
        loader: () async {
          loads++;
          return parseSubtitles(_vtt);
        },
      );
      final controller = ChewieController(
        videoPlayerController: vpc,
        subtitleTracks: [track],
      );
      await _settle();
      expect(loads, 0);

      controller.selectSubtitleTrack(track);
      await _settle();
      expect(loads, 1);
      expect(controller.liveSubtitle.value, isNull);

      await vpc.seekTo(const Duration(seconds: 2));
      expect(controller.liveSubtitle.value, '<i>Hello</i>');

      await vpc.seekTo(const Duration(seconds: 3, milliseconds: 600));
      expect(
        controller.liveSubtitle.value,
        '<i>Hello</i>\nOverlapping line\nsecond line',
      );

      await vpc.seekTo(const Duration(seconds: 5));
      expect(controller.liveSubtitle.value, 'Overlapping line\nsecond line');

      await vpc.seekTo(const Duration(seconds: 8));
      expect(controller.liveSubtitle.value, isNull);

      controller.selectSubtitleTrack(null);
      await vpc.seekTo(const Duration(seconds: 2));
      expect(controller.liveSubtitle.value, isNull);

      controller.selectSubtitleTrack(track);
      await _settle();
      expect(controller.liveSubtitle.value, '<i>Hello</i>');
      expect(loads, 1);

      controller.dispose();
    });

    test('an active track given up front is loaded at once', () async {
      await vpc.seekTo(const Duration(seconds: 1));
      final controller = ChewieController(
        videoPlayerController: vpc,
        subtitleTracks: [
          SubtitleTrack(id: 'en', label: 'en', loader: () async => _cues('A')),
        ],
        activeSubtitleTrackId: 'en',
      );
      await _settle();
      expect(controller.liveSubtitle.value, 'A');
      controller.dispose();
    });

    test('a slower earlier load never overrides the later selection', () async {
      final slow = Completer<List<Subtitle>>();
      final first = SubtitleTrack(
        id: 'en',
        label: 'en',
        loader: () => slow.future,
      );
      final second = SubtitleTrack(
        id: 'fr',
        label: 'fr',
        loader: () async => _cues('Français'),
      );
      final controller = ChewieController(
        videoPlayerController: vpc,
        subtitleTracks: [first, second],
      );

      controller.selectSubtitleTrack(first);
      controller.selectSubtitleTrack(second);
      await _settle();
      expect(controller.liveSubtitle.value, 'Français');

      slow.complete(_cues('English'));
      await _settle();
      expect(controller.liveSubtitle.value, 'Français');
      expect(controller.activeSubtitleTrackId, 'fr');

      controller.selectSubtitleTrack(null);
      final third = Completer<List<Subtitle>>();
      final late = SubtitleTrack(
        id: 'de',
        label: 'de',
        loader: () => third.future,
      );
      controller.setSubtitleTracks([first, second, late]);
      controller.selectSubtitleTrack(late);
      controller.selectSubtitleTrack(null);
      third.complete(_cues('Deutsch'));
      await _settle();
      expect(controller.liveSubtitle.value, isNull);

      controller.dispose();
    });

    test(
      'a failed load is reported, turns the track off and retries',
      () async {
        var attempts = 0;
        final track = SubtitleTrack(
          id: 'en',
          label: 'en',
          loader: () async {
            attempts++;
            if (attempts == 1) throw const SocketException('offline');
            return _cues('Back online');
          },
        );
        final errors = <(SubtitleTrack, Object)>[];
        final selections = <SubtitleTrack?>[];
        final controller = ChewieController(
          videoPlayerController: vpc,
          subtitleTracks: [track],
          onSubtitleTrackChanged: selections.add,
          onSubtitleError: (track, error, _) => errors.add((track, error)),
        );
        var notified = 0;
        controller.addListener(() => notified++);

        controller.selectSubtitleTrack(track);
        await _settle();
        expect(errors.single.$1, track);
        expect(errors.single.$2, isA<SocketException>());
        expect(controller.activeSubtitleTrackId, isNull);
        expect(controller.liveSubtitle.value, isNull);
        expect(selections, [track, null]);
        expect(notified, 2);

        controller.selectSubtitleTrack(track);
        await _settle();
        expect(attempts, 2);
        expect(controller.liveSubtitle.value, 'Back online');

        controller.dispose();
      },
    );

    test('one failed fetch is reported once', () async {
      final pending = Completer<List<Subtitle>>();
      final track = SubtitleTrack(
        id: 'en',
        label: 'en',
        loader: () => pending.future,
      );
      final errors = <Object>[];
      final controller = ChewieController(
        videoPlayerController: vpc,
        subtitleTracks: [track],
        onSubtitleError: (_, error, _) => errors.add(error),
      );
      controller.selectSubtitleTrack(track);
      controller.selectSubtitleTrack(null);
      controller.selectSubtitleTrack(track);

      pending.completeError(StateError('offline'));
      await _settle();

      expect(errors, hasLength(1));
      expect(controller.activeSubtitleTrackId, isNull);
      controller.dispose();
    });

    test(
      'a replaced track with the same id never shows the old cues',
      () async {
        final old = Completer<List<Subtitle>>();
        SubtitleTrack english(Future<List<Subtitle>> Function() loader) =>
            SubtitleTrack(id: 'en', label: 'en', loader: loader);
        final stale = english(() => old.future);
        final controller = ChewieController(
          videoPlayerController: vpc,
          subtitleTracks: [stale],
          activeSubtitleTrackId: 'en',
        );

        // For example a signed URL refreshed while the first one loads.
        controller.setSubtitleTracks([english(() async => _cues('Fresh'))]);
        await _settle();
        old.complete(_cues('Stale'));
        await _settle();

        expect(controller.liveSubtitle.value, 'Fresh');
        controller.dispose();
      },
    );

    test('without onSubtitleError the failure goes to FlutterError', () async {
      final reported = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previous);

      final track = SubtitleTrack(
        id: 'en',
        label: 'en',
        loader: () async => throw StateError('boom'),
      );
      final controller = ChewieController(
        videoPlayerController: vpc,
        subtitleTracks: [track],
      );
      controller.selectSubtitleTrack(track);
      await _settle();

      expect(reported.single.exception, isA<StateError>());
      expect(reported.single.library, 'chewie');
      controller.dispose();
    });

    test('disposing during a load is harmless', () async {
      final pending = Completer<List<Subtitle>>();
      final errors = <Object>[];
      final track = SubtitleTrack(
        id: 'en',
        label: 'en',
        loader: () => pending.future,
      );
      final controller = ChewieController(
        videoPlayerController: vpc,
        subtitleTracks: [track],
        onSubtitleError: (_, error, _) => errors.add(error),
      );
      controller.selectSubtitleTrack(track);
      controller.dispose();

      pending.complete(_cues('late'));
      await _settle();
      expect(errors, isEmpty);
      await vpc.seekTo(const Duration(seconds: 1));
    });

    test('cues follow the receiver while casting', () async {
      final cast = FakeCastController();
      final track = SubtitleTrack(
        id: 'en',
        label: 'en',
        loader: () async => _cues('On the TV', startSeconds: 60),
      );
      final controller = ChewieController(
        videoPlayerController: vpc,
        castController: cast,
        castMedia: const CastMedia(url: 'https://example.com/v.m3u8'),
        subtitleTracks: [track],
        activeSubtitleTrackId: 'en',
      );
      await _settle();
      expect(controller.liveSubtitle.value, isNull);

      cast.completeConnection();
      cast.emitRemoteValue(
        const VideoPlayerValue(
          duration: Duration(minutes: 5),
          position: Duration(seconds: 61),
          isInitialized: true,
        ),
      );
      expect(controller.isCasting, isTrue);
      expect(controller.liveSubtitle.value, 'On the TV');

      controller.dispose();
      expect(cast.hasAnyListeners, isFalse);
    });

    test('tracks without a source are still fed by the host', () async {
      final selections = <SubtitleTrack?>[];
      const track = SubtitleTrack(id: 'hls', label: 'HLS');
      final controller = ChewieController(
        videoPlayerController: vpc,
        subtitleTracks: const [track],
        onSubtitleTrackChanged: selections.add,
      );
      controller.selectSubtitleTrack(track);
      controller.setLiveSubtitle('From the host');
      await vpc.seekTo(const Duration(seconds: 30));
      await _settle();

      expect(selections, [track]);
      expect(controller.liveSubtitle.value, 'From the host');
      controller.dispose();
    });

    test('defaultSubtitleTrack follows preferredLanguages', () {
      ChewieController withLanguages(List<String> languages) =>
          ChewieController(
            videoPlayerController: vpc,
            preferredLanguages: languages,
            subtitleTracks: const [
              SubtitleTrack(id: 1, label: 'English', language: 'en'),
              SubtitleTrack(id: 2, label: 'Português', language: 'pt-BR'),
              SubtitleTrack(id: 3, label: 'Français', language: 'fr'),
            ],
          );

      expect(withLanguages(const []).defaultSubtitleTrack?.id, 1);
      expect(withLanguages(const ['fr']).defaultSubtitleTrack?.id, 3);
      expect(withLanguages(const ['de', 'PT']).defaultSubtitleTrack?.id, 2);
      expect(withLanguages(const ['fr-CA']).defaultSubtitleTrack?.id, 3);
      expect(withLanguages(const ['de']).defaultSubtitleTrack?.id, 1);
      expect(
        ChewieController(videoPlayerController: vpc).defaultSubtitleTrack,
        isNull,
      );
    });

    test('platform stays untouched', () {
      expect(platform.audioTrackReads, 0);
    });
  });

  group('url', () {
    late HttpServer server;
    late VideoPlayerController vpc;

    setUp(() async {
      // The test binding answers every HttpClient request with a 400.
      final overrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = overrides);
      FakeVideoPlayerPlatform.install();
      vpc = _network();
      await vpc.initialize();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        final response = request.response;
        switch (request.uri.path) {
          case '/en.vtt':
            response.write(_vtt);
          case '/fr.srt':
            response.write(_srt);
          default:
            response.statusCode = HttpStatus.notFound;
        }
        response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      await vpc.dispose();
    });

    Uri at(String path) => Uri.parse('http://127.0.0.1:${server.port}$path');

    Future<void> waitFor(bool Function() condition) async {
      for (var i = 0; i < 200 && !condition(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    test('downloads WebVTT and SubRip files', () async {
      final en = SubtitleTrack(id: 'en', label: 'en', url: at('/en.vtt'));
      final fr = SubtitleTrack(id: 'fr', label: 'fr', url: at('/fr.srt'));
      final controller = ChewieController(
        videoPlayerController: vpc,
        subtitleTracks: [en, fr],
      );
      await vpc.seekTo(const Duration(seconds: 2));

      controller.selectSubtitleTrack(en);
      await waitFor(() => controller.liveSubtitle.value != null);
      expect(controller.liveSubtitle.value, '<i>Hello</i>');

      controller.selectSubtitleTrack(fr);
      await waitFor(() => controller.liveSubtitle.value != null);
      await vpc.seekTo(const Duration(seconds: 1));
      expect(controller.liveSubtitle.value, 'Bonjour');

      controller.dispose();
    });

    test('reports an HTTP error', () async {
      final errors = <Object>[];
      final track = SubtitleTrack(id: 'x', label: 'x', url: at('/missing'));
      final controller = ChewieController(
        videoPlayerController: vpc,
        subtitleTracks: [track],
        activeSubtitleTrackId: 'x',
        onSubtitleError: (_, error, _) => errors.add(error),
      );
      await waitFor(() => errors.isNotEmpty);

      expect(errors.single, isA<HttpException>());
      expect((errors.single as HttpException).message, 'HTTP 404');
      expect(controller.activeSubtitleTrackId, isNull);
      controller.dispose();
    });
  });

  group('controls render loaded cues', () {
    final skins = <String, (Widget, TargetPlatform, IconData)>{
      'Material': (
        const MaterialControls(),
        TargetPlatform.android,
        Icons.closed_caption_off_outlined,
      ),
      'Material desktop': (
        const MaterialDesktopControls(),
        TargetPlatform.macOS,
        Icons.subtitles,
      ),
      'Cupertino': (
        const CupertinoControls(
          backgroundColor: Colors.black,
          iconColor: Colors.white,
        ),
        TargetPlatform.iOS,
        Icons.subtitles,
      ),
    };

    setUp(FakeVideoPlayerPlatform.install);

    for (final MapEntry(key: name, value: (controls, targetPlatform, toggle))
        in skins.entries) {
      testWidgets('$name: the toggle loads the preferred track and shows its '
          'cue', (tester) async {
        final loaded = <String>[];
        SubtitleTrack track(String language, String text) => SubtitleTrack(
          id: language,
          label: language,
          language: language,
          loader: () async {
            loaded.add(language);
            return _cues(text);
          },
        );
        final controller = ChewieController(
          videoPlayerController: _network(),
          autoInitialize: true,
          customControls: controls,
          preferredLanguages: const ['fr'],
          subtitleTracks: [track('en', 'Hello'), track('fr', 'Bonjour')],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: targetPlatform),
            home: Scaffold(body: Chewie(controller: controller)),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(loaded, isEmpty);

        await tester.tap(find.byIcon(toggle));
        await tester.pump();
        await tester.pump();

        expect(loaded, ['fr']);
        expect(controller.activeSubtitleTrackId, 'fr');
        expect(find.text('Bonjour'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        unawaited(controller.videoPlayerController.dispose());
        await tester.pump();
        controller.dispose();
      });

      testWidgets('$name: a failed load turns the toggle back off', (
        tester,
      ) async {
        var attempts = 0;
        final errors = <Object>[];
        final controller = ChewieController(
          videoPlayerController: _network(),
          autoInitialize: true,
          customControls: controls,
          onSubtitleError: (_, error, _) => errors.add(error),
          subtitleTracks: [
            SubtitleTrack(
              id: 'en',
              label: 'en',
              loader: () async {
                if (++attempts == 1) throw StateError('offline');
                return _cues('Second try');
              },
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: targetPlatform),
            home: Scaffold(body: Chewie(controller: controller)),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byIcon(toggle));
        await tester.pump();
        await tester.pump();
        expect(errors, hasLength(1));
        expect(controller.activeSubtitleTrackId, isNull);
        expect(find.byIcon(toggle), findsOneWidget);

        // Off again, so the next tap turns it on and retries.
        await tester.tap(find.byIcon(toggle));
        await tester.pump();
        await tester.pump();
        expect(attempts, 2);
        expect(find.text('Second try'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        unawaited(controller.videoPlayerController.dispose());
        await tester.pump();
        controller.dispose();
      });
    }
  });
}
