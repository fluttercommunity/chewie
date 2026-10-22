import 'package:chewie/chewie.dart';
import 'package:chewie/src/material/widgets/audio_track_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tracks = <AudioTrack>[
  AudioTrack(id: '0', label: 'English', language: 'en'),
  AudioTrack(id: '1', label: 'French', language: 'fr'),
  AudioTrack(id: '2', label: 'No language'),
];

/// Pumps a screen with a button that opens the [AudioTrackDialog] in a modal
/// bottom sheet, taps it, and lets the caller inspect/interact with the sheet.
/// The chosen track (or null) lands in [resultHolder] once the sheet closes.
Future<void> _openDialog(
  WidgetTester tester, {
  required Object? selectedId,
  required List<AudioTrack?> resultHolder,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                final track = await showModalBottomSheet<AudioTrack>(
                  context: context,
                  builder: (_) =>
                      AudioTrackDialog(tracks: _tracks, selectedId: selectedId),
                );
                resultHolder.add(track);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders one tile per track with its label', (tester) async {
    await _openDialog(tester, selectedId: '0', resultHolder: []);

    expect(find.byType(ListTile), findsNWidgets(_tracks.length));
    expect(find.text('English'), findsOneWidget);
    expect(find.text('French'), findsOneWidget);
    expect(find.text('No language'), findsOneWidget);
  });

  testWidgets('shows a check icon next to the selected track only', (
    tester,
  ) async {
    await _openDialog(tester, selectedId: '1', resultHolder: []);

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('shows the language code only for tracks that have one', (
    tester,
  ) async {
    await _openDialog(tester, selectedId: null, resultHolder: []);

    expect(find.text('en'), findsOneWidget);
    expect(find.text('fr'), findsOneWidget);
  });

  testWidgets('tapping a track pops the sheet with that track', (tester) async {
    final result = <AudioTrack?>[];
    await _openDialog(tester, selectedId: '0', resultHolder: result);

    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();

    expect(result, [_tracks[1]]);
  });

  testWidgets('dismissing the sheet pops with null', (tester) async {
    final result = <AudioTrack?>[];
    await _openDialog(tester, selectedId: '0', resultHolder: result);

    // Tap the scrim above the sheet to dismiss it.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result, [null]);
  });
}
