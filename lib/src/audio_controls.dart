import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import 'player_with_controls.dart';

class MediaState {
  MediaState(this.mediaItem, this.position);
  final MediaItem? mediaItem;
  final Duration position;
}

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  AudioPlayerHandler();
  late StreamController<PlaybackState> streamController;

  MediaItem? media;
  AudioPlayer? audioPlayer;
  Duration? position;

  late void Function(Duration)? _videoSeek;
  late void Function()? _videoPlay;
  late void Function()? _videoPause;
  late void Function()? _videoStop;

  void setMedia(MediaItem newMedia) {
    media = newMedia;
    audioPlayer = AudioPlayer();
    audioPlayer?.createPositionStream();
    audioPlayer?.setUrl(
      media!.id,
      tag: newMedia,
    );
  }

  Future<void> startBgPlay(Duration position, double speed) async {
    await audioPlayer?.seek(position);
    await audioPlayer!.setSpeed(speed);
    await audioPlayer?.play();
  }

  Duration? stopBgPlay() {
    audioPlayer?.stop();

    return position;
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
  Future<void> play() async {
    if (isInBg) {
      await audioPlayer!.play();
      return;
    }
    _videoPlay!();
  }

  @override
  Future<void> pause() async {
    if (isInBg) {
      await audioPlayer!.pause();
      return;
    }
    _videoPause!();
  }

  @override
  Future<void> seek(Duration position) async {
    if (isInBg) {
      await audioPlayer!.seek(position);
      return;
    }
    _videoSeek!(position);
  }

  @override
  Future<void> stop() async {
    if (isInBg) {
      await audioPlayer!.seek(Duration.zero);
      return;
    }
    _videoStop!();
  }

  void dispose() {
    streamController.add(
      PlaybackState(),
    );
  }

  void initializeStreamController(
    VideoPlayerController? videoPlayerController,
  ) {
    bool isPlaying() => isInBg
        ? audioPlayer?.playing ?? false
        : videoPlayerController?.value.isPlaying ?? false;

    AudioProcessingState processingState() {
      if (videoPlayerController == null) return AudioProcessingState.idle;
      if (videoPlayerController.value.isInitialized) {
        return AudioProcessingState.ready;
      }
      return AudioProcessingState.idle;
    }

    Duration bufferedPosition() {
      if (audioPlayer != null && audioPlayer!.playing) {
        try {
          return audioPlayer!.bufferedPosition;
        } catch (err) {
          return Duration.zero;
        }
      }

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
          updatePosition: ((audioPlayer?.playing ?? false)
                  ? audioPlayer?.position
                  : videoPlayerController?.value.position) ??
              Duration.zero,
          bufferedPosition: bufferedPosition(),
          speed: videoPlayerController?.value.playbackSpeed ?? 1.0,
        ),
      );
    }

    void startStream() {
      videoPlayerController?.addListener(addVideoEvent);
      audioPlayer?.playbackEventStream.listen((data) {
        addVideoEvent();
      });
      audioPlayer?.positionStream.listen((data) {
        position = data;
      });
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
