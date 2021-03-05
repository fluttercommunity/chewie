import 'dart:async';

import 'package:chewie_audio/src/chewie_progress_colors.dart';
import 'package:chewie_audio/src/player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

typedef ChewieRoutePageBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  _ChewieAudioControllerProvider controllerProvider,
);

/// An Audio Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. ChewieAudio wraps it in a friendly skin to
/// make it easy to use!
class ChewieAudio extends StatelessWidget {
  const ChewieAudio({
    Key? key,
    required this.controller,
  }) : super(key: key);

  /// The [ChewieAudioController]
  final ChewieAudioController controller;

  @override
  Widget build(BuildContext context) {
    return _ChewieAudioControllerProvider(
      controller: controller,
      child: const PlayerWithControls(),
    );
  }
}

/// The ChewieController is used to configure and drive the Chewie Player
/// Widgets. It provides methods to control playback, such as [pause] and
/// [play], as well as methods that control the visual appearance of the player,
/// such as [enterFullScreen] or [exitFullScreen].
///
/// In addition, you can listen to the ChewieController for presentational
/// changes, such as entering and exiting full screen mode. To listen for
/// changes to the playback, such as a change to the seek position of the
/// player, please use the standard information provided by the
/// `VideoPlayerController`.
class ChewieAudioController extends ChangeNotifier {
  ChewieAudioController({
    required this.videoPlayerController,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.cupertinoProgressColors,
    this.materialProgressColors,
    this.showControls = true,
    this.customControls,
    this.errorBuilder,
    this.isLive = false,
    this.allowMuting = true,
    this.allowPlaybackSpeedChanging = true,
    this.playbackSpeeds = const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2],
  }) : assert(playbackSpeeds.every((speed) => speed > 0),
            'The playbackSpeeds values must all be greater than 0') {
    _initialize();
  }

  /// The controller for the video you want to play
  final VideoPlayerController videoPlayerController;

  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Start video at a certain position
  final Duration? startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// Whether or not to show the controls at all
  final bool showControls;

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget? customControls;

  /// When the video playback runs into an error, you can build a custom
  /// error message.
  final Widget Function(BuildContext context, String? errorMessage)?
    errorBuilder;

  /// The colors to use for controls on iOS. By default, the iOS player uses
  /// colors sampled from the original iOS 11 designs.
  final ChewieProgressColors? cupertinoProgressColors;

  /// The colors to use for the Material Progress Bar. By default, the Material
  /// player uses the colors from your Theme.
  final ChewieProgressColors? materialProgressColors;

  /// Defines if the controls should be for live stream video
  final bool isLive;

  /// Defines if the mute control should be shown
  final bool allowMuting;

  /// Defines if the playback speed control should be shown
  final bool allowPlaybackSpeedChanging;

  /// Defines the set of allowed playback speeds user can change
  final List<double> playbackSpeeds;

  static ChewieAudioController of(BuildContext context) {
    final chewieAudioControllerProvider = context
        .dependOnInheritedWidgetOfExactType<_ChewieAudioControllerProvider>()!;

    return chewieAudioControllerProvider.controller;
  }

  bool get isPlaying => videoPlayerController.value.isPlaying;

  Future _initialize() async {
    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.isInitialized) {
      await videoPlayerController.initialize();
    }

    if (autoPlay) {
      await videoPlayerController.play();
    }

    if (startAt != null) {
      await videoPlayerController.seekTo(startAt!);
    }
  }

  void togglePause() {
    isPlaying ? pause() : play();
  }

  Future<void> play() async {
    await videoPlayerController.play();
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  Future<void> pause() async {
    await videoPlayerController.pause();
  }

  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);
  }

  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
  }
}

class _ChewieAudioControllerProvider extends InheritedWidget {
  const _ChewieAudioControllerProvider({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  final ChewieAudioController controller;

  @override
  bool updateShouldNotify(_ChewieAudioControllerProvider old) =>
      controller != old.controller;
}
