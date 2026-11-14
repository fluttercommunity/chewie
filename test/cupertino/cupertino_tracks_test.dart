import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import '../fake_video_player_platform.dart';

const _subtitleTracks = <SubtitleTrack>[
  SubtitleTrack(id: 'en', label: 'English', language: 'en'),
  SubtitleTrack(id: 'fr', label: 'French', language: 'fr'),
];

const _audioTracks = <AudioTrack>[
  AudioTrack(id: 'a0', label: 'Original', language: 'en'),
  AudioTrack(id: 'a1', label: 'Dubbed', language: 'fr'),
];

ChewieController _controller({
  List<SubtitleTrack> subtitleTracks = const <SubtitleTrack>[],
  Object? activeSubtitleTrackId,
  void Function(SubtitleTrack?)? onSubtitleTrackChanged,
  List<AudioTrack> audioTracks = const <AudioTrack>[],
  Object? activeAudioTrackId,
  void Function(AudioTrack)? onAudioTrackChanged,
  Subtitles? subtitle,
  bool showSubtitles = false,
  OptionsTranslation? optionsTranslation,
  Future<void> Function(BuildContext, List<OptionItem>)? optionsBuilder,
  Widget? customControls,
}) {
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video.m3u8'),
    ),
    autoPlay: false,
    subtitleTracks: subtitleTracks,
    activeSubtitleTrackId: activeSubtitleTrackId,
    onSubtitleTrackChanged: onSubtitleTrackChanged,
    audioTracks: audioTracks,
    activeAudioTrackId: activeAudioTrackId,
    onAudioTrackChanged: onAudioTrackChanged,
    subtitle: subtitle,
    showSubtitles: showSubtitles,
    optionsTranslation: optionsTranslation,
    optionsBuilder: optionsBuilder,
    customControls: customControls,
  );
}

Future<void> _pumpOnIOS(
  WidgetTester tester,
  ChewieController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      home: Scaffold(body: Chewie(controller: controller)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.byType(CupertinoControls), findsOneWidget);
}

Future<void> _openOption(WidgetTester tester, String title) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

Future<void> _teardown(WidgetTester tester, ChewieController controller) async {
  await tester.pumpWidget(const SizedBox());
  unawaited(controller.videoPlayerController.dispose());
  await tester.pump();
  controller.dispose();
}

void main() {
  setUp(FakeVideoPlayerPlatform.install);

  testWidgets('without tracks: no toggle, no options button, no live cue', (
    tester,
  ) async {
    final controller = _controller();
    await _pumpOnIOS(tester, controller);

    expect(find.byIcon(Icons.subtitles), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);

    controller.setLiveSubtitle('Live cue');
    await tester.pump();
    expect(find.text('Live cue'), findsNothing);

    await _teardown(tester, controller);
  });

  testWidgets('without tracks: a static subtitle cue still renders', (
    tester,
  ) async {
    final controller = _controller(
      showSubtitles: true,
      subtitle: Subtitles([
        Subtitle(
          index: 0,
          start: Duration.zero,
          end: const Duration(hours: 1),
          text: 'Static cue',
        ),
      ]),
    );
    await _pumpOnIOS(tester, controller);

    expect(find.byIcon(Icons.subtitles), findsOneWidget);
    expect(find.text('Static cue'), findsOneWidget);

    await _teardown(tester, controller);
  });

  testWidgets('the audio picker marks the active track and selects another', (
    tester,
  ) async {
    AudioTrack? chosen;
    final controller = _controller(
      audioTracks: _audioTracks,
      activeAudioTrackId: 'a0',
      onAudioTrackChanged: (track) => chosen = track,
    );
    await _pumpOnIOS(tester, controller);

    await _openOption(tester, 'Audio');
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Dubbed'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('Dubbed'));
    await tester.pumpAndSettle();

    expect(chosen, _audioTracks[1]);
    expect(controller.activeAudioTrackId, 'a1');

    await _teardown(tester, controller);
  });

  testWidgets('a single audio track adds no Audio entry', (tester) async {
    final controller = _controller(
      audioTracks: [_audioTracks.first],
      subtitleTracks: _subtitleTracks,
    );
    await _pumpOnIOS(tester, controller);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Subtitles'), findsOneWidget);
    expect(find.text('Audio'), findsNothing);

    await _teardown(tester, controller);
  });

  testWidgets('the subtitle picker selects a track, then Off clears it', (
    tester,
  ) async {
    final selections = <SubtitleTrack?>[];
    final controller = _controller(
      subtitleTracks: _subtitleTracks,
      activeSubtitleTrackId: 'en',
      onSubtitleTrackChanged: selections.add,
    );
    await _pumpOnIOS(tester, controller);

    await _openOption(tester, 'Subtitles');
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();
    expect(selections.last, _subtitleTracks[1]);
    expect(controller.activeSubtitleTrackId, 'fr');

    await _openOption(tester, 'Subtitles');
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(selections.last, isNull);
    expect(controller.activeSubtitleTrackId, isNull);

    await _teardown(tester, controller);
  });

  testWidgets('the picker uses the translated subtitles labels', (
    tester,
  ) async {
    final controller = _controller(
      subtitleTracks: _subtitleTracks,
      optionsTranslation: OptionsTranslation(subtitlesButtonText: 'Captions'),
    );
    await _pumpOnIOS(tester, controller);

    await _openOption(tester, 'Captions');
    expect(find.text('Captions — off'), findsOneWidget);

    await _teardown(tester, controller);
  });

  testWidgets('the live cue shows only while a track is on', (tester) async {
    final selections = <SubtitleTrack?>[];
    final controller = _controller(
      subtitleTracks: _subtitleTracks,
      activeSubtitleTrackId: 'en',
      onSubtitleTrackChanged: selections.add,
    );
    await _pumpOnIOS(tester, controller);

    controller.setLiveSubtitle('Live cue');
    await tester.pump();
    expect(find.text('Live cue'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.subtitles));
    await tester.pump();
    expect(selections.last, isNull);
    expect(find.text('Live cue'), findsNothing);

    controller.setLiveSubtitle('Ignored cue');
    await tester.pump();
    expect(find.text('Ignored cue'), findsNothing);

    await tester.tap(find.byIcon(Icons.subtitles));
    await tester.pump();
    expect(selections.last, _subtitleTracks.first);

    controller.setLiveSubtitle('Back on');
    await tester.pump();
    expect(find.text('Back on'), findsOneWidget);

    await _teardown(tester, controller);
  });

  testWidgets('tracks set after the first frame appear', (tester) async {
    final controller = _controller(
      customControls: const CupertinoControls(
        backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
        iconColor: Color.fromARGB(255, 200, 200, 200),
      ),
    );
    await _pumpOnIOS(tester, controller);
    expect(find.byIcon(Icons.subtitles), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);

    controller.setSubtitleTracks(_subtitleTracks);
    controller.setAudioTracks(_audioTracks);
    await tester.pump();

    expect(find.byIcon(Icons.subtitles), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Subtitles'), findsOneWidget);

    await _teardown(tester, controller);
  });

  testWidgets('optionsBuilder receives the track entries with their icons', (
    tester,
  ) async {
    List<OptionItem>? received;
    final controller = _controller(
      subtitleTracks: _subtitleTracks,
      audioTracks: _audioTracks,
      optionsBuilder: (context, options) async => received = options,
    );
    await _pumpOnIOS(tester, controller);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();

    expect(received?.map((option) => option.iconData), [
      Icons.audiotrack_outlined,
      Icons.subtitles_outlined,
    ]);

    await _teardown(tester, controller);
  });
}
