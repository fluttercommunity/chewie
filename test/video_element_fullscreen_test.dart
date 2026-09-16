import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

final Uri _src = Uri.parse(
  'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4',
);

class _RouteCounter extends NavigatorObserver {
  int pushes = 0;
  int pops = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pops++;
  }
}

void main() {
  late _RouteCounter routes;
  late ChewieController controller;

  Future<void> pumpPlayer(WidgetTester tester) async {
    routes = _RouteCounter();
    controller = ChewieController(
      videoPlayerController: VideoPlayerController.networkUrl(_src),
      autoPlay: false,
      looping: false,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [routes],
        home: Scaffold(
          body: Column(
            children: [
              const Text('host page'),
              Expanded(child: Chewie(controller: controller)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('fullscreen on a browser without the Fullscreen API', () {
    setUp(() => ChewieState.debugUsesVideoElementFullScreen = true);
    tearDown(() => ChewieState.debugUsesVideoElementFullScreen = null);

    testWidgets('entering fullscreen pushes no route', (
      WidgetTester tester,
    ) async {
      await pumpPlayer(tester);
      final pushesBefore = routes.pushes;

      controller.enterFullScreen();
      await tester.pumpAndSettle();

      expect(routes.pushes, pushesBefore);
      expect(controller.isFullScreen, isTrue);
      expect(find.text('host page'), findsOneWidget);
    });

    testWidgets('leaving fullscreen pops nothing, so the host page stays', (
      WidgetTester tester,
    ) async {
      await pumpPlayer(tester);

      controller.enterFullScreen();
      await tester.pumpAndSettle();
      controller.exitFullScreen();
      await tester.pumpAndSettle();

      expect(routes.pops, 0);
      expect(controller.isFullScreen, isFalse);
      expect(find.text('host page'), findsOneWidget);
      expect(find.byType(Chewie), findsOneWidget);
    });

    testWidgets('a redundant exit request still leaves the host page alone', (
      WidgetTester tester,
    ) async {
      await pumpPlayer(tester);

      controller.enterFullScreen();
      await tester.pumpAndSettle();
      controller.exitFullScreen();
      controller.exitFullScreen();
      await tester.pumpAndSettle();

      expect(routes.pops, 0);
      expect(find.text('host page'), findsOneWidget);
    });
  });

  testWidgets('the fullscreen route is still used where the API exists', (
    WidgetTester tester,
  ) async {
    ChewieState.debugUsesVideoElementFullScreen = false;
    addTearDown(() => ChewieState.debugUsesVideoElementFullScreen = null);

    await pumpPlayer(tester);
    final pushesBefore = routes.pushes;

    controller.enterFullScreen();
    await tester.pumpAndSettle();

    expect(routes.pushes, pushesBefore + 1);

    controller.exitFullScreen();
    await tester.pumpAndSettle();

    expect(routes.pops, 1);
    expect(find.text('host page'), findsOneWidget);
  });
}
