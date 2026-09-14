import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

const _tracks = <AudioTrack>[
  AudioTrack(id: '0', label: 'English', language: 'en'),
  AudioTrack(id: '1', label: 'French', language: 'fr'),
];

/// Builds a [ChewieController] that never touches the video_player platform
/// (autoInitialize/autoPlay stay false) but exposes the two audio tracks.
ChewieController _controller(
  Widget controls, {
  void Function(AudioTrack)? onChanged,
}) {
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/v.mp4'),
    ),
    autoPlay: false,
    autoInitialize: false,
    audioTracks: _tracks,
    activeAudioTrackId: '0',
    onAudioTrackChanged: onChanged,
    customControls: controls,
  );
}

/// Opens the options menu via [optionsIcon], taps the "Audio" entry, then picks
/// "French" — exercising the controls' audio-track code path end to end.
Future<void> _runFlow(
  WidgetTester tester, {
  required Widget controls,
  required IconData optionsIcon,
}) async {
  AudioTrack? chosen;
  final controller = _controller(controls, onChanged: (t) => chosen = t);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Chewie(controller: controller)),
    ),
  );
  // Let the show-controls-on-initialize timer fire so the controls become
  // interactive (otherwise AbsorbPointer swallows the tap).
  await tester.pump(const Duration(milliseconds: 300));

  // Open the options bottom sheet.
  await tester.tap(find.byIcon(optionsIcon));
  await tester.pumpAndSettle();
  expect(find.text('Audio'), findsOneWidget);

  // Open the audio-track dialog.
  await tester.tap(find.text('Audio'));
  await tester.pumpAndSettle();
  expect(find.text('English'), findsOneWidget);
  expect(find.text('French'), findsOneWidget);

  // Pick a track.
  await tester.tap(find.text('French'));
  await tester.pumpAndSettle();

  expect(chosen, _tracks[1]);
  expect(controller.activeAudioTrackId, '1');
}

void main() {
  testWidgets('MaterialControls: options menu exposes audio-track selection', (
    tester,
  ) async {
    await _runFlow(
      tester,
      controls: const MaterialControls(),
      optionsIcon: Icons.more_vert,
    );
  });

  testWidgets(
    'MaterialDesktopControls: options menu exposes audio-track selection',
    (tester) async {
      await _runFlow(
        tester,
        controls: const MaterialDesktopControls(),
        optionsIcon: Icons.settings,
      );
    },
  );

  testWidgets('the Audio entry is hidden when there is only one track', (
    tester,
  ) async {
    final controller = ChewieController(
      videoPlayerController: VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/v.mp4'),
      ),
      autoPlay: false,
      autoInitialize: false,
      audioTracks: const [AudioTrack(id: '0', label: 'English')],
      customControls: const MaterialControls(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Chewie(controller: controller)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Audio'), findsNothing);
  });
}
