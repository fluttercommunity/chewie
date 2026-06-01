import 'package:chewie/chewie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

const _tracks = <AudioTrack>[
  AudioTrack(id: '0', label: 'English', language: 'en'),
  AudioTrack(id: '1', label: 'French', language: 'fr'),
];

ChewieController _controllerWith({
  List<AudioTrack> audioTracks = const <AudioTrack>[],
  Object? activeAudioTrackId,
  void Function(AudioTrack track)? onAudioTrackChanged,
}) {
  // autoInitialize/autoPlay stay false, so no platform plugin call is made.
  return ChewieController(
    videoPlayerController: VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/v.mp4'),
    ),
    audioTracks: audioTracks,
    activeAudioTrackId: activeAudioTrackId,
    onAudioTrackChanged: onAudioTrackChanged,
  );
}

void main() {
  // Needed so VideoPlayerController construction and setLooping (a no-op while
  // uninitialized) don't trip over the missing test binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChewieController.hasAudioTracks', () {
    test('is false with no tracks', () {
      expect(_controllerWith().hasAudioTracks, isFalse);
    });

    test('is false with a single track (nothing to choose)', () {
      expect(
        _controllerWith(
          audioTracks: const [AudioTrack(id: '0', label: 'A')],
        ).hasAudioTracks,
        isFalse,
      );
    });

    test('is true with two or more tracks', () {
      expect(_controllerWith(audioTracks: _tracks).hasAudioTracks, isTrue);
    });
  });

  test('setAudioTracks replaces the tracks and notifies listeners', () {
    final controller = _controllerWith();
    var notified = 0;
    controller.addListener(() => notified++);

    controller.setAudioTracks(_tracks);

    expect(controller.audioTracks, _tracks);
    expect(controller.hasAudioTracks, isTrue);
    expect(notified, 1);
  });

  test(
    'selectAudioTrack updates the active id, fires the callback and notifies',
    () {
      AudioTrack? selected;
      final controller = _controllerWith(
        audioTracks: _tracks,
        onAudioTrackChanged: (track) => selected = track,
      );
      var notified = 0;
      controller.addListener(() => notified++);

      controller.selectAudioTrack(_tracks[1]);

      expect(controller.activeAudioTrackId, '1');
      expect(selected, _tracks[1]);
      expect(notified, 1);
    },
  );

  test('selectAudioTrack works without an onAudioTrackChanged callback', () {
    final controller = _controllerWith(audioTracks: _tracks);
    expect(() => controller.selectAudioTrack(_tracks[0]), returnsNormally);
    expect(controller.activeAudioTrackId, '0');
  });

  test('copyWith carries the audio-track fields over', () {
    final controller = _controllerWith();
    final copy = controller.copyWith(
      audioTracks: _tracks,
      activeAudioTrackId: '1',
    );

    expect(copy.audioTracks, _tracks);
    expect(copy.activeAudioTrackId, '1');
  });

  test('copyWith keeps the original audio-track fields when omitted', () {
    final controller = _controllerWith(
      audioTracks: _tracks,
      activeAudioTrackId: '0',
    );
    final copy = controller.copyWith(autoPlay: false);

    expect(copy.audioTracks, _tracks);
    expect(copy.activeAudioTrackId, '0');
  });
}
