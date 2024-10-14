import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:video_player/video_player.dart';

class MediaState {
  MediaState(this.mediaItem, this.position);
  final MediaItem? mediaItem;
  final Duration position;
}

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  AudioPlayerHandler();
  late StreamController<PlaybackState> streamController;

  MediaItem? media;

  late void Function(Duration)? _videoSeek;
  late void Function()? _videoPlay;
  late void Function()? _videoPause;
  late void Function()? _videoStop;

  void setMedia(MediaItem newMedia) {
    media = newMedia;
  }

  void setVideoFunctions(
    void Function() play,
    void Function() pause,
    void Function(Duration duration) seek,
    void Function() stop,
  ) {
    _videoPlay = play;
    _videoPause = pause;
    _videoSeek = seek;
    _videoStop = stop;
    mediaItem.add(media);
  }

  // In this simple example, we handle only 4 actions: play, pause, seek and
  // stop. Any button press from the Flutter UI, notification, lock screen or
  // headset will be routed through to these 4 methods so that you can handle
  // your audio playback logic in one place.

  @override
  Future<void> play() async => _videoPlay!();

  @override
  Future<void> pause() async => _videoPause!();

  @override
  Future<void> seek(Duration position) async => _videoSeek!(position);

  @override
  Future<void> stop() async => _videoStop!();

  void initializeStreamController(
    VideoPlayerController? videoPlayerController,
  ) {
    bool isPlaying() => videoPlayerController?.value.isPlaying ?? false;

    AudioProcessingState processingState() {
      if (videoPlayerController == null) return AudioProcessingState.idle;
      if (videoPlayerController.value.isInitialized) {
        return AudioProcessingState.ready;
      }
      return AudioProcessingState.idle;
    }

    Duration bufferedPosition() {
      try {
        final currentBufferedRange =
            videoPlayerController?.value.buffered.firstWhere((durationRange) {
          final position = videoPlayerController.value.position;
          final isCurrentBufferedRange =
              durationRange.start < position && durationRange.end > position;
          return isCurrentBufferedRange;
        });
        if (currentBufferedRange == null) return Duration.zero;
        return currentBufferedRange.end;
      } catch (err) {
        return Duration.zero;
      }
    }

    void addVideoEvent() {
      streamController.add(
        PlaybackState(
          controls: [
            MediaControl.rewind,
            if (isPlaying()) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.fastForward,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: processingState(),
          playing: isPlaying(),
          updatePosition:
              videoPlayerController?.value.position ?? Duration.zero,
          bufferedPosition: bufferedPosition(),
          speed: videoPlayerController?.value.playbackSpeed ?? 1.0,
        ),
      );
    }

    void startStream() {
      videoPlayerController?.addListener(addVideoEvent);
    }

    void stopStream() {
      videoPlayerController?.removeListener(addVideoEvent);
      streamController.close();
    }

    streamController = StreamController<PlaybackState>(
      onListen: startStream,
      onPause: stopStream,
      onResume: startStream,
      onCancel: stopStream,
    );
  }
}
