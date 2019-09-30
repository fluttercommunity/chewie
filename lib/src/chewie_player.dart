import 'dart:async';

import 'package:chewie_audio/src/chewie_progress_colors.dart';
import 'package:chewie_audio/src/player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// An Audio Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. ChewieAudio wraps it in a friendly skin to
/// make it easy to use!
class ChewieAudio extends StatelessWidget {
  ChewieAudio({
    Key key,
    this.controller,
  })  : assert(
            controller != null, 'You must provide a chewie audio controller'),
        super(key: key);

  /// The [ChewieAudioController]
  final ChewieAudioController controller;

  @override
  Widget build(BuildContext context) {
    return _ChewieAudioControllerProvider(
      controller: controller,
      child: PlayerWithControls(),
    );
  }
}

/// The ChewieAudioController is used to configure and drive the Chewie Audio Player
/// Widgets. It provides methods to control playback, such as [pause] and
/// [play], as well as methods that control the visual appearance of the player.
///
/// To listen for changes to the playback, such as a change to the seek position of the
/// player, please use the standard information provided by the
/// `VideoPlayerController`.
class ChewieAudioController extends ChangeNotifier {
  ChewieAudioController({
    this.videoPlayerController,
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
  }) : assert(videoPlayerController != null,
            'You must provide a controller to play a video') {
    _initialize();
  }

  /// The controller for the audio you want to play
  final VideoPlayerController videoPlayerController;

  /// Initialize the Audio on Startup. This will prep the audio for playback.
  final bool autoInitialize;

  /// Play the audio as soon as it's initialized
  final bool autoPlay;

  /// Start audio at a certain position
  final Duration startAt;

  /// Whether or not the audio should loop
  final bool looping;

  /// Whether or not to show the controls at all
  final bool showControls;

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget customControls;

  /// When the video playback runs  into an error, you can build a custom
  /// error message.
  final Widget Function(BuildContext context, String errorMessage) errorBuilder;

  /// The colors to use for controls on iOS. By default, the iOS player uses
  /// colors sampled from the original iOS 11 designs.
  final ChewieProgressColors cupertinoProgressColors;

  /// The colors to use for the Material Progress Bar. By default, the Material
  /// player uses the colors from your Theme.
  final ChewieProgressColors materialProgressColors;

  /// Defines if the controls should be for live stream audio
  final bool isLive;

  /// Defines if the mute control should be shown
  final bool allowMuting;

  static ChewieAudioController of(BuildContext context) {
    final chewieAudioControllerProvider =
        context.inheritFromWidgetOfExactType(_ChewieAudioControllerProvider)
            as _ChewieAudioControllerProvider;

    return chewieAudioControllerProvider.controller;
  }

  Future _initialize() async {
    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.initialized) {
      await videoPlayerController.initialize();
    }

    if (autoPlay) {
      await videoPlayerController.play();
    }

    if (startAt != null) {
      await videoPlayerController.seekTo(startAt);
    }
  }

  Future<void> play() async {
    await videoPlayerController.play();
  }

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
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null),
        assert(child != null),
        super(key: key, child: child);

  final ChewieAudioController controller;

  @override
  bool updateShouldNotify(_ChewieAudioControllerProvider old) =>
      controller != old.controller;
}
