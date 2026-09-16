import 'dart:async';

import 'package:chewie/src/material/widgets/subtitle_track_dialog.dart';
import 'package:chewie/src/models/subtitle_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tracks = <SubtitleTrack>[
  SubtitleTrack(id: 'en', label: 'English', language: 'en'),
  SubtitleTrack(id: 'fr', label: 'French', language: 'fr'),
];

Future<SubtitleTrackChoice?> _openDialog(
  WidgetTester tester, {
  Object? selectedId,
  String offLabel = 'Off',
}) async {
  SubtitleTrackChoice? result;
  late BuildContext sheetContext;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            sheetContext = context;
            return const SizedBox();
          },
        ),
      ),
    ),
  );

  unawaited(
    showModalBottomSheet<SubtitleTrackChoice>(
      context: sheetContext,
      builder: (context) => SubtitleTrackDialog(
        tracks: _tracks,
        selectedId: selectedId,
        offLabel: offLabel,
      ),
    ).then((value) => result = value),
  );

  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('renders the Off entry plus one tile per track', (tester) async {
    await _openDialog(tester, selectedId: 'en');

    expect(find.text('Off'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('French'), findsOneWidget);
    // The language hint is shown as trailing text.
    expect(find.text('en'), findsOneWidget);
    expect(find.text('fr'), findsOneWidget);
    // The selected track shows a check icon.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('honours a custom off label', (tester) async {
    await _openDialog(tester, selectedId: null, offLabel: 'Subtitles — off');
    expect(find.text('Subtitles — off'), findsOneWidget);
    // With nothing selected, the Off entry carries the check.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('tapping a track pops a choice carrying that track', (
    tester,
  ) async {
    SubtitleTrackChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  choice = await showModalBottomSheet<SubtitleTrackChoice>(
                    context: context,
                    builder: (context) => const SubtitleTrackDialog(
                      tracks: _tracks,
                      selectedId: 'en',
                    ),
                  );
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

    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();

    expect(choice, isNotNull);
    expect(choice!.track, isNotNull);
    expect(choice!.track!.id, 'fr');
  });

  testWidgets('tapping Off pops a choice with a null track', (tester) async {
    SubtitleTrackChoice? choice;
    var popped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  choice = await showModalBottomSheet<SubtitleTrackChoice>(
                    context: context,
                    builder: (context) => const SubtitleTrackDialog(
                      tracks: _tracks,
                      selectedId: 'en',
                    ),
                  );
                  popped = true;
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

    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(choice, isNotNull);
    expect(choice!.track, isNull);
  });
}
