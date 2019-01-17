import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The state of the [ChewieController].
@immutable
class ChewieValue {
  ChewieValue({
    this.isFullScreen = false,
  });

  /// True if the video is currently playing fullscreen
  final bool isFullScreen;

  ChewieValue copyWith({
    VideoPlayerController videoPlayerController,
    bool isFullScreen,
  }) {
    return ChewieValue(
      isFullScreen: isFullScreen ?? this.isFullScreen,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'isFullscreen: $isFullScreen, ';
  }
}

class ChewieController extends ValueNotifier<ChewieValue> {
  ChewieController({
    this.videoPlayerController,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    this.cupertinoProgressColors,
    this.materialProgressColors,
    this.placeholder,
    this.showControls = true,
    this.allowedScreenSleep = true,
    this.isLive = false,
  })  : assert(videoPlayerController != null,
            'You must provide a controller to play a video'),
        super(ChewieValue()) {
    _initialize();
  }

  /// The controller for the video you want to play
  final VideoPlayerController videoPlayerController;

  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Start video at a certain position
  final Duration startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// Whether or not to show the controls
  final bool showControls;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  final double aspectRatio;

  /// The colors to use for controls on iOS. By default, the iOS player uses
  /// colors sampled from the original iOS 11 designs.
  final ChewieProgressColors cupertinoProgressColors;

  /// The colors to use for the Material Progress Bar. By default, the Material
  /// player uses the colors from your Theme.
  final ChewieProgressColors materialProgressColors;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget placeholder;

  /// Defines if the player will start in fullscreen when play is pressed
  final bool fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  final bool allowedScreenSleep;

  /// Defines if the controls should be for live stream video
  final bool isLive;

  bool get isFullScreen => value.isFullScreen;

  Future _initialize() async {
    await videoPlayerController.setLooping(looping);

    if (autoInitialize || autoPlay) {
      await videoPlayerController.initialize();
    }

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullscreen();
      }

      await videoPlayerController.play();
    }

    if (startAt != null) {
      await videoPlayerController.seekTo(startAt);
    }

    if (fullScreenByDefault) {
      videoPlayerController.addListener(() async {
        if (await videoPlayerController.value.isPlaying &&
            !value.isFullScreen) {
          enterFullscreen();
        }
      });
    }
  }

  void enterFullscreen() {
    value = value.copyWith(isFullScreen: true);
  }

  void exitFullscreen() {
    value = value.copyWith(isFullScreen: false);
  }

  void toggleFullscreen() {
    value = value.copyWith(isFullScreen: !value.isFullScreen);
  }

  void play() {
    videoPlayerController.play();
  }

  void pause() {
    videoPlayerController.pause();
  }
}

class ChewieControllerProvider extends InheritedWidget {
  const ChewieControllerProvider({
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null),
        assert(child != null),
        super(key: key, child: child);

  final ChewieController controller;

  static ChewieController of(BuildContext context) {
    final ChewieControllerProvider chewieControllerProvider =
        context.inheritFromWidgetOfExactType(ChewieControllerProvider);

    return chewieControllerProvider.controller;
  }

  @override
  bool updateShouldNotify(ChewieControllerProvider old) =>
      controller != old.controller;
}
