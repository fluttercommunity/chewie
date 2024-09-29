import 'package:chewie/chewie.dart';
import 'package:chewie/src/center_play_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

List<String> srcs = [
  'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4',
  'https://assets.mixkit.co/videos/preview/mixkit-daytime-city-traffic-aerial-view-56-large.mp4',
  'https://assets.mixkit.co/videos/preview/mixkit-a-girl-blowing-a-bubble-gum-at-an-amusement-park-1226-large.mp4',
];

void main() {
  testWidgets('MaterialControls state test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(srcs[0]),
    );
    final materialControlsKey = GlobalKey();
    final chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      customControls: MaterialControls(
        key: materialControlsKey,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Chewie(
            controller: chewieController,
          ),
        ),
      ),
    );

    await tester.pump();

    final playButton = find.byType(CenterPlayButton);
    expect(playButton, findsOneWidget);
    final btn = playButton.first;
    final playButtonWidget = tester.widget<CenterPlayButton>(btn);
    expect(playButtonWidget.isFinished, false);
  });

  testWidgets('CupertinoControls state test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(srcs[0]),
    );
    final materialControlsKey = GlobalKey();
    final chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      customControls: CupertinoControls(
        key: materialControlsKey,
        backgroundColor: Colors.black,
        iconColor: Colors.white,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Chewie(
            controller: chewieController,
          ),
        ),
      ),
    );

    await tester.pump();

    final playButton = find.byType(CenterPlayButton);
    expect(playButton, findsOneWidget);
    final btn = playButton.first;
    final playButtonWidget = tester.widget<CenterPlayButton>(btn);
    expect(playButtonWidget.isFinished, false);
  });

  testWidgets('MaterialDesktopControls state test',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(srcs[0]),
    );
    final materialControlsKey = GlobalKey();
    final chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      customControls: MaterialDesktopControls(
        key: materialControlsKey,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Chewie(
            controller: chewieController,
          ),
        ),
      ),
    );

    await tester.pump();

    final playButton = find.byType(CenterPlayButton);
    expect(playButton, findsOneWidget);
    final btn = playButton.first;
    final playButtonWidget = tester.widget<CenterPlayButton>(btn);
    expect(playButtonWidget.isFinished, false);
  });
}
