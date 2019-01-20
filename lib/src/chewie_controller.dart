import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ChewieController extends ChangeNotifier {
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
    this.customControls,
    this.allowedScreenSleep = true,
    this.isLive = false,
  }) : assert(videoPlayerController != null,
            'You must provide a controller to play a video') {
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

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget customControls;

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

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  Future _initialize() async {
    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.initialized) {
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
        if (await videoPlayerController.value.isPlaying && !_isFullScreen) {
          enterFullscreen();
        }
      });
    }
  }

  void enterFullscreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  void exitFullscreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  void toggleFullscreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
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
