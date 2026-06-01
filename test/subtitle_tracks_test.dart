import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

final Uri _src = Uri.parse(
  'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4',
);

const _tracks = <SubtitleTrack>[
  SubtitleTrack(id: 'en', label: 'English', language: 'en'),
  SubtitleTrack(id: 'fr', label: 'French', language: 'fr'),
];

ChewieController _controller({
  List<SubtitleTrack> tracks = const <SubtitleTrack>[],
  Object? activeSubtitleTrackId,
  void Function(SubtitleTrack?)? onSubtitleTrackChanged,
  Widget Function(BuildContext, dynamic)? subtitleBuilder,
  Subtitles? subtitle,
  bool showSubtitles = false,
  OptionsTranslation? optionsTranslation,
  Widget? customControls,
}) {
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(_src),
    autoPlay: false,
    looping: false,
    subtitleTracks: tracks,
    activeSubtitleTrackId: activeSubtitleTrackId,
    onSubtitleTrackChanged: onSubtitleTrackChanged,
    subtitleBuilder: subtitleBuilder,
    subtitle: subtitle,
    showSubtitles: showSubtitles,
    optionsTranslation: optionsTranslation,
    customControls: customControls,
  );
}

void main() {
  group('ChewieController subtitle tracks', () {
    test('hasSubtitleTracks reflects the track list', () {
      final controller = _controller();
      expect(controller.hasSubtitleTracks, isFalse);

      var notified = 0;
      controller.addListener(() => notified++);
      controller.setSubtitleTracks(_tracks);

      expect(controller.hasSubtitleTracks, isTrue);
      expect(controller.subtitleTracks, _tracks);
      expect(notified, 1);
    });

    test('selectSubtitleTrack sets the active id and notifies the host', () {
      SubtitleTrack? received;
      var called = 0;
      final controller = _controller(
        tracks: _tracks,
        onSubtitleTrackChanged: (track) {
          received = track;
          called++;
        },
      );

      controller.selectSubtitleTrack(_tracks[1]);
      expect(controller.activeSubtitleTrackId, 'fr');
      expect(called, 1);
      expect(received, _tracks[1]);
    });

    test('selecting the null track clears the live cue', () {
      final controller = _controller(tracks: _tracks);
      controller.setLiveSubtitle('a cue on screen');
      expect(controller.liveSubtitle.value, 'a cue on screen');

      controller.selectSubtitleTrack(null);
      expect(controller.activeSubtitleTrackId, isNull);
      expect(controller.liveSubtitle.value, isNull);
    });

    test('setLiveSubtitle pushes cue text through the notifier', () {
      final controller = _controller(tracks: _tracks);
      controller.setLiveSubtitle('hello');
      expect(controller.liveSubtitle.value, 'hello');
      controller.setLiveSubtitle(null);
      expect(controller.liveSubtitle.value, isNull);
    });

    test('copyWith carries the subtitle-track fields', () {
      onChanged(SubtitleTrack? _) {}
      final controller = _controller();
      final copy = controller.copyWith(
        subtitleTracks: _tracks,
        activeSubtitleTrackId: 'fr',
        onSubtitleTrackChanged: onChanged,
      );

      expect(copy.subtitleTracks, _tracks);
      expect(copy.activeSubtitleTrackId, 'fr');
      expect(copy.onSubtitleTrackChanged, same(onChanged));
    });

    test('copyWith without subtitle args preserves the originals', () {
      onChanged(SubtitleTrack? _) {}
      final controller = _controller(
        tracks: _tracks,
        activeSubtitleTrackId: 'en',
        onSubtitleTrackChanged: onChanged,
      );
      final copy = controller.copyWith();

      expect(copy.subtitleTracks, _tracks);
      expect(copy.activeSubtitleTrackId, 'en');
      expect(copy.onSubtitleTrackChanged, same(onChanged));
    });

    test('dispose releases the live-subtitle notifier', () {
      final controller = _controller(tracks: _tracks);
      controller.dispose();
      // Touching a disposed ValueNotifier throws in debug builds.
      expect(
        () => controller.liveSubtitle.addListener(() {}),
        throwsFlutterError,
      );
    });
  });

  // Reveal the controls overlay: showControlsOnInitialize flips hideStuff to
  // false after ~200ms, which lifts the AbsorbPointer so taps land.
  Future<void> reveal(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final variant in <String>['material', 'desktop']) {
    final isMaterial = variant == 'material';
    Widget controls() =>
        isMaterial ? const MaterialControls() : const MaterialDesktopControls();
    // Material swaps the toggle icon with state; desktop keeps a fixed icon.
    final toggleOnIcon = isMaterial ? Icons.closed_caption : Icons.subtitles;
    final toggleOffIcon = isMaterial
        ? Icons.closed_caption_off_outlined
        : Icons.subtitles;
    final optionsIcon = isMaterial ? Icons.more_vert : Icons.settings;

    group('$variant controls subtitle UI', () {
      testWidgets('shows the toggle and live cue when a track is active', (
        tester,
      ) async {
        final controller = _controller(
          tracks: _tracks,
          activeSubtitleTrackId: 'en',
          customControls: controls(),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Chewie(controller: controller)),
          ),
        );
        await reveal(tester);

        // Active subtitles => the toggle is shown in its "on" state.
        expect(find.byIcon(toggleOnIcon), findsOneWidget);

        controller.setLiveSubtitle('Live cue text');
        await tester.pump();
        expect(find.text('Live cue text'), findsOneWidget);

        // Empty cue text renders nothing.
        controller.setLiveSubtitle('');
        await tester.pump();
        expect(find.text(''), findsNothing);
      });

      testWidgets('tapping the toggle drives track selection', (tester) async {
        final selections = <SubtitleTrack?>[];
        final controller = _controller(
          tracks: _tracks,
          activeSubtitleTrackId: 'en',
          onSubtitleTrackChanged: selections.add,
          customControls: controls(),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Chewie(controller: controller)),
          ),
        );
        await reveal(tester);

        // Starts on -> tapping turns it off (null track).
        await tester.tap(find.byIcon(toggleOnIcon));
        await tester.pump();
        expect(selections.last, isNull);
        expect(controller.activeSubtitleTrackId, isNull);
        expect(find.byIcon(toggleOffIcon), findsOneWidget);

        // Tapping again turns it back on, defaulting to the active track.
        await tester.tap(find.byIcon(toggleOffIcon));
        await tester.pump();
        expect(selections.last, _tracks[0]);
      });

      testWidgets('the options menu opens the track picker', (tester) async {
        final selections = <SubtitleTrack?>[];
        final controller = _controller(
          tracks: _tracks,
          onSubtitleTrackChanged: selections.add,
          customControls: controls(),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Chewie(controller: controller)),
          ),
        );
        await reveal(tester);

        await tester.tap(find.byIcon(optionsIcon));
        await tester.pumpAndSettle();
        expect(find.text('Subtitles'), findsOneWidget);

        await tester.tap(find.text('Subtitles'));
        await tester.pumpAndSettle();

        // Track picker is open: Off + the two tracks.
        expect(find.text('Off'), findsOneWidget);
        await tester.tap(find.text('French'));
        await tester.pumpAndSettle();

        expect(selections.last, _tracks[1]);
        expect(controller.activeSubtitleTrackId, 'fr');
      });

      testWidgets('the picker uses the translated off label', (tester) async {
        final controller = _controller(
          tracks: _tracks,
          optionsTranslation: OptionsTranslation(
            subtitlesButtonText: 'Captions',
          ),
          customControls: controls(),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Chewie(controller: controller)),
          ),
        );
        await reveal(tester);

        await tester.tap(find.byIcon(optionsIcon));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Captions'));
        await tester.pumpAndSettle();

        // Material threads the translated label into the picker's "off" entry;
        // the desktop variant always uses the default "Off".
        expect(
          find.text(isMaterial ? 'Captions — off' : 'Off'),
          findsOneWidget,
        );
      });

      testWidgets('renders a static subtitle cue when no tracks exist', (
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
          customControls: controls(),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Chewie(controller: controller)),
          ),
        );
        await reveal(tester);

        expect(find.text('Static cue'), findsOneWidget);
      });

      testWidgets('a custom subtitleBuilder renders the live cue', (
        tester,
      ) async {
        final controller = _controller(
          tracks: _tracks,
          activeSubtitleTrackId: 'en',
          subtitleBuilder: (context, text) => Text('built:$text'),
          customControls: controls(),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Chewie(controller: controller)),
          ),
        );
        await reveal(tester);

        controller.setLiveSubtitle('cue');
        await tester.pump();
        expect(find.text('built:cue'), findsOneWidget);
      });
    });
  }
}
