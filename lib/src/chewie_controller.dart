import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The state of the [ChewieController].
@immutable
class ChewieValue {
  ChewieValue(
    this.videoPlayerController, {
    this.isFullScreen = false,
  });

  /// True if the video is currently playing fullscreen
  final bool isFullScreen;

  /// The controller for the video you want to play
  final VideoPlayerController videoPlayerController;

  ChewieValue copyWith({
    VideoPlayerController videoPlayerController,
    bool isFullScreen,
  }) {
    return ChewieValue(
      videoPlayerController ?? this.videoPlayerController,
      isFullScreen: isFullScreen ?? this.isFullScreen,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'isFullscreen: $isFullScreen, '
        'videoPlayerController: $videoPlayerController, ';
  }
}

class ChewieController extends ValueNotifier<ChewieValue> {
  ChewieController(
    VideoPlayerController videoPlayerController, {
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
        super(ChewieValue(videoPlayerController)) {
    _initialize();
  }

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

  Future _initialize() async {
    await value.videoPlayerController.setLooping(looping);

    if (autoInitialize || autoPlay) {
      await value.videoPlayerController.initialize();
    }

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullscreen();
      }

      await value.videoPlayerController.play();
    }

    if (startAt != null) {
      await value.videoPlayerController.seekTo(startAt);
    }

    if (fullScreenByDefault) {
      value.videoPlayerController.addListener(() async {
        if (await value.videoPlayerController.value.isPlaying &&
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
    value.videoPlayerController.play();
  }

  void pause() {
    value.videoPlayerController.pause();
  }

  // TODO: Do we really need the ability to change the controller?
  set videoPlayerController(VideoPlayerController controller) {
    if (value.videoPlayerController.dataSource != controller.dataSource) {
      // FIXME: The VideoPlayer widget still tries to access the controller
      value.videoPlayerController.dispose();
      value = value.copyWith(videoPlayerController: controller);
      exitFullscreen();
      _initialize();
    }
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
