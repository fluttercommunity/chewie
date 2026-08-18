import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import 'fake_cast_controller.dart';
import 'fake_video_player_platform.dart';

const _src =
    'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4';

const _livingRoom = CastDevice(
  id: 'living-room',
  name: 'Living Room TV',
  modelName: 'Chromecast Ultra',
);
const _kitchen = CastDevice(id: 'kitchen', name: 'Kitchen Display');

const _media = CastMedia(url: _src, mimeType: 'video/mp4', title: 'Earth');

ChewieController _buildController({
  ChewieCastController? castController,
  bool allowCasting = true,
  Widget? customControls,
}) {
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(Uri.parse(_src)),
    autoPlay: false,
    looping: false,
    castController: castController,
    castMedia: castController == null ? null : _media,
    allowCasting: allowCasting,
    customControls: customControls ?? const MaterialControls(),
  );
}

Future<void> _pumpPlayer(
  WidgetTester tester,
  ChewieController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Chewie(controller: controller)),
    ),
  );
  // The skins start with the controls hidden behind an AbsorbPointer and only
  // reveal them on a short timer, so taps miss until that has fired.
  await tester.pump(const Duration(milliseconds: 300));
}

/// Pumps a fixed window rather than settling.
///
/// The cast button pulses for as long as a connection is in flight and the
/// picker shows a spinner while scanning; both are indefinite, so
/// `pumpAndSettle` would simply time out.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Scopes an icon finder to the cast button — the casting overlay uses the same
/// glyphs, so an unscoped `find.byIcon` matches twice mid-session.
Finder _castButtonIcon(IconData icon) =>
    find.descendant(of: find.byType(CastButton), matching: find.byIcon(icon));

void main() {
  setUp(FakeVideoPlayerPlatform.install);

  group('cast button visibility', () {
    testWidgets('is absent when no cast controller is configured', (
      tester,
    ) async {
      await _pumpPlayer(tester, _buildController());

      expect(find.byType(CastButton), findsNothing);
    });

    testWidgets('is shown once a cast controller is configured', (
      tester,
    ) async {
      await _pumpPlayer(
        tester,
        _buildController(castController: FakeCastController()),
      );

      expect(find.byType(CastButton), findsOneWidget);
      expect(_castButtonIcon(Icons.cast), findsOneWidget);
    });

    testWidgets('is hidden by allowCasting: false', (tester) async {
      await _pumpPlayer(
        tester,
        _buildController(
          castController: FakeCastController(),
          allowCasting: false,
        ),
      );

      expect(find.byType(CastButton), findsNothing);
    });

    testWidgets('appears in the Cupertino skin too', (tester) async {
      await _pumpPlayer(
        tester,
        _buildController(
          castController: FakeCastController(),
          customControls: const CupertinoControls(
            backgroundColor: Colors.black,
            iconColor: Colors.white,
          ),
        ),
      );

      expect(find.byType(CastButton), findsOneWidget);
    });

    testWidgets('appears in the desktop skin too', (tester) async {
      await _pumpPlayer(
        tester,
        _buildController(
          castController: FakeCastController(),
          customControls: const MaterialDesktopControls(),
        ),
      );

      expect(find.byType(CastButton), findsOneWidget);
    });
  });

  group('additionalControls', () {
    const marker = Key('extra-control');

    Future<void> expectSlotHonoured(WidgetTester tester, Widget skin) async {
      await _pumpPlayer(
        tester,
        ChewieController(
          videoPlayerController: VideoPlayerController.networkUrl(
            Uri.parse(_src),
          ),
          autoPlay: false,
          additionalControls: (_) => const [SizedBox(key: marker, width: 24)],
          customControls: skin,
        ),
      );

      expect(find.byKey(marker), findsOneWidget);
    }

    testWidgets('appears in the Material control bar', (tester) async {
      await expectSlotHonoured(tester, const MaterialControls());
    });

    testWidgets('appears in the desktop control bar', (tester) async {
      await expectSlotHonoured(tester, const MaterialDesktopControls());
    });

    testWidgets('appears in the Cupertino control bar', (tester) async {
      await expectSlotHonoured(
        tester,
        const CupertinoControls(
          backgroundColor: Colors.black,
          iconColor: Colors.white,
        ),
      );
    });

    testWidgets('is absent when not supplied', (tester) async {
      await _pumpPlayer(tester, _buildController());

      expect(find.byKey(marker), findsNothing);
    });
  });

  group('control bar styling', () {
    /// Stands in for a supplied control that styles itself from the bar, the
    /// way `chewie_cast`'s AirPlay button does.
    Widget styledIcon() {
      return Builder(
        builder: (context) {
          final style = ChewieControlStyle.maybeOf(context);
          final child = Padding(
            padding: style?.padding ?? EdgeInsets.zero,
            child: Icon(Icons.airplay, size: style?.iconSize ?? 24),
          );
          return style?.decorate(child) ?? child;
        },
      );
    }

    Future<void> pumpStyled(WidgetTester tester, Widget skin) async {
      await _pumpPlayer(
        tester,
        ChewieController(
          videoPlayerController: VideoPlayerController.networkUrl(
            Uri.parse(_src),
          ),
          autoPlay: false,
          additionalControls: (_) => [styledIcon()],
          customControls: skin,
        ),
      );
    }

    /// A control bar is shorter than its nominal height once the progress bar
    /// has taken its share — the desktop bar leaves its buttons about 28
    /// logical pixels. Padding the bar does not itself use eats into that and
    /// crushes the glyph's box below the glyph; the glyph is still drawn at
    /// full size, so it paints outside its own bounds and sits low among its
    /// neighbours instead of centred like them.
    ///
    /// A box larger than the glyph is fine — Cupertino stretches it to the bar
    /// height and centres the glyph inside. Smaller is the bug.
    void expectRoomForGlyph(WidgetTester tester, double iconSize) {
      final box = tester.getSize(find.byIcon(Icons.airplay));

      expect(box.height, greaterThanOrEqualTo(iconSize));
      expect(box.width, greaterThanOrEqualTo(iconSize));
    }

    testWidgets('the Material bar leaves room for its glyph', (tester) async {
      await pumpStyled(tester, const MaterialControls());

      expectRoomForGlyph(tester, 24);
    });

    testWidgets('the desktop bar leaves room for its glyph', (tester) async {
      await pumpStyled(tester, const MaterialDesktopControls());

      expectRoomForGlyph(tester, 24);
    });

    testWidgets('the Cupertino bar leaves room for its glyph', (tester) async {
      await pumpStyled(
        tester,
        const CupertinoControls(
          backgroundColor: Colors.black,
          iconColor: Colors.white,
        ),
      );

      expectRoomForGlyph(tester, 16);
    });
  });

  group('device picker', () {
    testWidgets('scans only while the picker is open', (tester) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      await _pumpPlayer(tester, _buildController(castController: cast));

      expect(cast.startDiscoveryCount, 0);

      await tester.tap(find.byType(CastButton));
      await _settle(tester);

      expect(cast.startDiscoveryCount, 1);
      expect(cast.stopDiscoveryCount, 0);

      Navigator.of(tester.element(find.byType(CastDevicesDialog))).pop();
      await _settle(tester);

      expect(cast.stopDiscoveryCount, 1);
    });

    testWidgets('lists discovered devices and connects to the tapped one', (
      tester,
    ) async {
      final cast = FakeCastController(devices: const [_livingRoom, _kitchen]);
      await _pumpPlayer(tester, _buildController(castController: cast));

      await tester.tap(find.byType(CastButton));
      await _settle(tester);

      expect(find.text('Living Room TV'), findsOneWidget);
      expect(find.text('Chromecast Ultra'), findsOneWidget);
      expect(find.text('Kitchen Display'), findsOneWidget);

      await tester.tap(find.text('Kitchen Display'));
      await _settle(tester);

      expect(cast.connectedDevice, _kitchen);
      expect(cast.connectionState, CastConnectionState.connecting);
    });

    testWidgets('says it is searching rather than empty while scanning', (
      tester,
    ) async {
      final cast = FakeCastController();
      await _pumpPlayer(tester, _buildController(castController: cast));

      await tester.tap(find.byType(CastButton));
      await _settle(tester);

      expect(find.text('Looking for devices…'), findsOneWidget);
      expect(find.text('No devices found'), findsNothing);

      // A device turning up mid-scan lands in the open list.
      cast.addDevice(_livingRoom);
      await _settle(tester);

      expect(find.text('Living Room TV'), findsOneWidget);
      expect(find.text('Looking for devices…'), findsNothing);
    });

    testWidgets('offers to stop casting while a session is live', (
      tester,
    ) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      await _pumpPlayer(tester, _buildController(castController: cast));

      await cast.connect(_livingRoom);
      cast.completeConnection();
      await _settle(tester);

      await tester.tap(find.byType(CastButton));
      await _settle(tester);

      await tester.tap(find.text('Stop casting'));
      await _settle(tester);

      expect(cast.connectionState, CastConnectionState.disconnected);
    });
  });

  group('handover', () {
    testWidgets('loads the cast media at the local position on connect', (
      tester,
    ) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      final controller = _buildController(castController: cast);
      await _pumpPlayer(tester, controller);

      await cast.connect(_livingRoom);
      cast.completeConnection();
      await _settle(tester);

      expect(cast.loadCalls, hasLength(1));
      expect(cast.loadCalls.single.media, _media);
      // The local player never initialises in tests, so it sits at zero — the
      // point is that the position is carried across at all.
      expect(
        cast.loadCalls.single.startAt,
        controller.videoPlayerController.value.position,
      );
      expect(cast.loadCalls.single.autoPlay, isFalse);
    });

    testWidgets('loads exactly once per session', (tester) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      await _pumpPlayer(tester, _buildController(castController: cast));

      await cast.connect(_livingRoom);
      cast.completeConnection();
      await _settle(tester);

      // Position ticks from the receiver must not re-trigger the handover.
      cast.emitRemoteValue(
        const VideoPlayerValue(
          duration: Duration(minutes: 5),
          position: Duration(seconds: 30),
          isInitialized: true,
          isPlaying: true,
        ),
      );
      await _settle(tester);

      expect(cast.loadCalls, hasLength(1));
    });

    testWidgets('does not reload media the receiver already holds', (
      tester,
    ) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      await _pumpPlayer(tester, _buildController(castController: cast));

      await cast.connect(_livingRoom);
      cast.completeConnection();
      await _settle(tester);

      expect(cast.loadCalls, hasLength(1));

      // Apps rebuild their ChewieController routinely — copyWith, switching
      // video. Each new instance starts un-handed-off, and without a guard it
      // would tell the receiver to load what it is already playing, restarting
      // playback on the TV.
      await _pumpPlayer(tester, _buildController(castController: cast));
      // A live receiver keeps ticking; that notification is what makes a fresh
      // ChewieController evaluate the handover at all.
      cast.emitRemoteValue(
        const VideoPlayerValue(
          duration: Duration(minutes: 5),
          position: Duration(seconds: 10),
          isInitialized: true,
          isPlaying: true,
        ),
      );
      await _settle(tester);

      expect(cast.loadCalls, hasLength(1));
    });

    testWidgets('still loads when the media differs', (tester) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      await _pumpPlayer(tester, _buildController(castController: cast));

      await cast.connect(_livingRoom);
      cast.completeConnection();
      await _settle(tester);
      expect(cast.loadCalls, hasLength(1));

      // A different video must still hand over.
      final other = ChewieController(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(_src),
        ),
        autoPlay: false,
        castController: cast,
        castMedia: const CastMedia(url: 'https://example.com/other.mp4'),
        customControls: const MaterialControls(),
      );
      await _pumpPlayer(tester, other);
      cast.emitRemoteValue(
        const VideoPlayerValue(
          duration: Duration(minutes: 5),
          position: Duration(seconds: 10),
          isInitialized: true,
          isPlaying: true,
        ),
      );
      await _settle(tester);

      expect(cast.loadCalls, hasLength(2));
      expect(cast.loadCalls.last.media.url, 'https://example.com/other.mp4');
    });

    testWidgets('resumes locally at the position the receiver reached', (
      tester,
    ) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      final controller = _buildController(castController: cast);
      await _pumpPlayer(tester, controller);

      await cast.connect(_livingRoom);
      cast.completeConnection();
      await _settle(tester);

      cast.emitRemoteValue(
        const VideoPlayerValue(
          duration: Duration(minutes: 5),
          position: Duration(seconds: 42),
          isInitialized: true,
          isPlaying: true,
        ),
      );
      await _settle(tester);

      await cast.disconnect();
      await _settle(tester);

      expect(controller.isCasting, isFalse);
      expect(
        controller.videoPlayerController.value.position,
        const Duration(seconds: 42),
      );
      // The receiver was playing, so the local player picks that up too.
      expect(controller.videoPlayerController.value.isPlaying, isTrue);

      // Stop the position poller the resumed player started; leaving it
      // running trips the "timer still pending" invariant at test teardown.
      await controller.videoPlayerController.pause();
    });

    testWidgets('a failed connection does not hand playback anywhere', (
      tester,
    ) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      final controller = _buildController(castController: cast);
      await _pumpPlayer(tester, controller);

      // connecting -> disconnected, never reaching connected.
      await cast.connect(_livingRoom);
      await tester.pump();
      await cast.disconnect();
      await _settle(tester);

      expect(cast.loadCalls, isEmpty);
      expect(controller.isCasting, isFalse);
      expect(controller.playback.isRemote, isFalse);
    });
  });

  group('while casting', () {
    testWidgets('the video surface is replaced by the casting overlay', (
      tester,
    ) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      await _pumpPlayer(tester, _buildController(castController: cast));

      expect(find.byType(VideoPlayer), findsOneWidget);
      expect(find.byType(CastOverlay), findsNothing);

      await cast.connect(_livingRoom);
      cast.completeConnection();
      await _settle(tester);

      expect(find.byType(VideoPlayer), findsNothing);
      expect(find.byType(CastOverlay), findsOneWidget);
      expect(find.text('Casting to Living Room TV'), findsOneWidget);
    });

    testWidgets('transport goes to the receiver, not the local player', (
      tester,
    ) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      final controller = _buildController(castController: cast);
      await _pumpPlayer(tester, controller);

      await cast.connect(_livingRoom);
      cast.completeConnection();
      await _settle(tester);

      expect(controller.playback.isRemote, isTrue);

      await controller.play();
      await controller.seekTo(const Duration(seconds: 12));
      await controller.setVolume(0.4);

      expect(cast.transportCalls, ['play', 'seekTo:12000', 'setVolume:0.4']);
      expect(controller.videoPlayerController.value.isPlaying, isFalse);
    });

    testWidgets('the controls read the receiver position', (tester) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      await _pumpPlayer(tester, _buildController(castController: cast));

      await cast.connect(_livingRoom);
      cast.completeConnection();
      await _settle(tester);

      cast.emitRemoteValue(
        const VideoPlayerValue(
          duration: Duration(minutes: 2),
          position: Duration(seconds: 75),
          isInitialized: true,
          isPlaying: true,
        ),
      );
      await _settle(tester);

      // MaterialControls renders "position / duration" as a RichText, which
      // find.textContaining does not traverse.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText && w.text.toPlainText().contains('01:15 / 02:00'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the button switches to the connected glyph', (tester) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      await _pumpPlayer(tester, _buildController(castController: cast));

      expect(_castButtonIcon(Icons.cast), findsOneWidget);

      await cast.connect(_livingRoom);
      cast.completeConnection();
      await _settle(tester);

      expect(_castButtonIcon(Icons.cast_connected), findsOneWidget);
    });
  });

  group('lifecycle', () {
    testWidgets('disposing Chewie leaves the app-owned cast controller alive', (
      tester,
    ) async {
      final cast = FakeCastController(devices: const [_livingRoom]);
      final controller = _buildController(castController: cast);
      await _pumpPlayer(tester, controller);

      // Tear the tree down first, so the only remaining subscriber is the
      // ChewieController itself.
      await tester.pumpWidget(const SizedBox());
      controller.dispose();

      // Still usable: Chewie unsubscribed but did not dispose it.
      expect(cast.hasAnyListeners, isFalse);
      await cast.startDiscovery();
      expect(cast.isDiscovering, isTrue);
    });

    testWidgets('a ChewieController without casting reports sane defaults', (
      tester,
    ) async {
      final controller = _buildController();
      await _pumpPlayer(tester, controller);

      expect(controller.isCasting, isFalse);
      expect(controller.castDevice, isNull);
      expect(controller.castConnectionState, CastConnectionState.disconnected);
      expect(controller.playback.isRemote, isFalse);
    });
  });
}
