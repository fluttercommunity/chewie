import 'package:chewie/chewie.dart';
import 'package:chewie/src/subtitle_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

ChewieController buildController({
  Widget Function(BuildContext, dynamic)? subtitleBuilder,
  SubtitleStyle subtitleStyle = const SubtitleStyle(),
}) {
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video.mp4'),
    ),
    autoPlay: false,
    looping: false,
    subtitleBuilder: subtitleBuilder,
    subtitleStyle: subtitleStyle,
  );
}

extension on WidgetTester {
  Future<void> pumpOverlay(ChewieController controller, dynamic text) {
    return pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubtitleOverlay(
            chewieController: controller,
            margin: const EdgeInsets.all(5),
            text: text,
          ),
        ),
      ),
    );
  }

  /// The cue as a viewer would read it.
  String renderedText() =>
      widget<Text>(find.byType(Text)).textSpan?.toPlainText() ??
      widget<Text>(find.byType(Text)).data!;
}

void main() {
  group('SubtitleOverlay', () {
    testWidgets('renders a cue with no markup as one plain run', (
      tester,
    ) async {
      const cue = 'Tu comprends ce qu\'ils disent ?';
      await tester.pumpOverlay(buildController(), cue);

      expect(tester.renderedText(), cue);

      final span = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
      expect(span.children, hasLength(1));
      expect(
        span.children!.single,
        isA<TextSpan>().having((leaf) => leaf.text, 'text', cue),
      );
      expect(span.style, const SubtitleStyle().textStyle);
      expect(span.children!.single.style, const SubtitleStyle().textStyle);
    });

    testWidgets('a cue with no markup reads the same either way', (
      tester,
    ) async {
      const cue = 'Tom & Jerry — 5 < 10\nsur deux lignes';

      await tester.pumpOverlay(buildController(), cue);
      final parsed = tester.renderedText();

      await tester.pumpOverlay(
        buildController(
          subtitleStyle: const SubtitleStyle(renderMarkup: false),
        ),
        cue,
      );

      expect(parsed, cue);
      expect(parsed, tester.renderedText());
    });

    testWidgets('renders markup instead of showing the tags', (tester) async {
      await tester.pumpOverlay(buildController(), '<i>italique</i>');

      expect(tester.renderedText(), 'italique');
      expect(find.textContaining('<i>', findRichText: true), findsNothing);
    });

    testWidgets('keeps markup while honouring a custom style', (tester) async {
      final controller = buildController(
        subtitleStyle: const SubtitleStyle(
          textStyle: TextStyle(fontSize: 30, color: Color(0xFFFFC107)),
          textAlign: TextAlign.left,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(color: Color(0xFF123456)),
        ),
      );
      await tester.pumpOverlay(controller, 'plain <b>bold</b>');

      expect(tester.renderedText(), 'plain bold');

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.textAlign, TextAlign.left);

      final span = text.textSpan! as TextSpan;
      final bold = span.children!.cast<TextSpan>().last;
      expect(bold.text, 'bold');
      expect(bold.style!.fontWeight, FontWeight.bold);
      expect(bold.style!.fontSize, 30);
      expect(bold.style!.color, const Color(0xFFFFC107));

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, const EdgeInsets.all(12));
      expect(
        container.decoration,
        const BoxDecoration(color: Color(0xFF123456)),
      );
    });

    testWidgets('shows the tags when markup rendering is off', (tester) async {
      final controller = buildController(
        subtitleStyle: const SubtitleStyle(renderMarkup: false),
      );
      await tester.pumpOverlay(controller, '<i>italique</i>');

      expect(tester.renderedText(), '<i>italique</i>');
    });

    testWidgets('hands subtitleBuilder the untouched cue', (tester) async {
      Object? received;
      final controller = buildController(
        subtitleBuilder: (context, dynamic subtitle) {
          received = subtitle;
          return Text('builder: $subtitle');
        },
      );
      await tester.pumpOverlay(controller, '<i>italique</i>');

      expect(received, '<i>italique</i>');
      expect(find.text('builder: <i>italique</i>'), findsOneWidget);
    });

    testWidgets('subtitleBuilder wins over the default box', (tester) async {
      final controller = buildController(
        subtitleBuilder: (context, dynamic subtitle) => const Text('custom'),
      );
      await tester.pumpOverlay(controller, 'ignored');

      expect(find.byType(Container), findsNothing);
      expect(find.text('custom'), findsOneWidget);
    });

    testWidgets('renders a ready-made span as-is', (tester) async {
      const span = TextSpan(
        text: 'pre-built',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
      await tester.pumpOverlay(buildController(), span);

      expect(tester.widget<Text>(find.byType(Text)).textSpan, same(span));
    });

    testWidgets('falls back to toString for other payloads', (tester) async {
      await tester.pumpOverlay(buildController(), 42);

      expect(tester.renderedText(), '42');
    });

    testWidgets('uses the margin supplied by the controls', (tester) async {
      await tester.pumpOverlay(buildController(), 'x');

      expect(
        tester.widget<Padding>(find.byType(Padding).first).padding,
        const EdgeInsets.all(5),
      );
    });

    testWidgets('draws an empty box for a cue that is only tags', (
      tester,
    ) async {
      await tester.pumpOverlay(buildController(), '<i></i>');

      expect(tester.takeException(), isNull);
      expect(tester.renderedText(), '');
    });

    testWidgets('still inherits the ambient text colour', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultTextStyle(
              style: const TextStyle(color: Color(0xFF00FF00)),
              child: SubtitleOverlay(
                chewieController: buildController(),
                margin: const EdgeInsets.all(5),
                text: 'ambient <b>bold</b>',
              ),
            ),
          ),
        ),
      );

      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      expect(paragraph.text.style!.color, const Color(0xFF00FF00));
    });

    testWidgets('still honours the platform text scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpOverlay(buildController(), 'scaled');

      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      expect(paragraph.textScaler.scale(10), 20);
    });
  });

  group('ChewieController', () {
    test('copyWith carries subtitleStyle over', () {
      const style = SubtitleStyle(renderMarkup: false);
      final controller = buildController(subtitleStyle: style);

      expect(controller.copyWith().subtitleStyle, style);
      expect(
        controller.copyWith(subtitleStyle: const SubtitleStyle()).subtitleStyle,
        const SubtitleStyle(),
      );
    });
  });
}
