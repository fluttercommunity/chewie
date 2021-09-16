import 'dart:async';

import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/material/models/options_translation.dart';
import 'package:chewie/src/models/subtitle_model.dart';
import 'package:chewie/src/notifiers/player_notifier.dart';
import 'package:chewie/src/player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import 'material/models/option_item.dart';

typedef ChewieRoutePageBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  _ChewieControllerProvider controllerProvider,
);

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. Chewie wraps it in a friendly skin to
/// make it easy to use!
class Chewie extends StatefulWidget {
  const Chewie({
    Key? key,
    required this.controller,
  }) : super(key: key);

  /// The [ChewieController]
  final ChewieController controller;

  @override
  ChewieState createState() {
    return ChewieState();
  }
}

class ChewieState extends State<Chewie> {
  bool _isFullScreen = false;
  late PlayerNotifier notifier;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
    notifier = PlayerNotifier.init();
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    super.dispose();
  }

  @override
  void didUpdateWidget(Chewie oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> listener() async {
    if (widget.controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      Navigator.of(context, rootNavigator: true).pop();
      _isFullScreen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ChewieControllerProvider(
      controller: widget.controller,
      child: ChangeNotifierProvider<PlayerNotifier>.value(
        value: notifier,
        builder: (context, w) => const PlayerWithControls(),
      ),
    );
  }

  Widget _buildFullScreenVideo(
    BuildContext context,
    Animation<double> animation,
    _ChewieControllerProvider controllerProvider,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: controllerProvider,
      ),
    );
  }

  AnimatedWidget _defaultRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    _ChewieControllerProvider controllerProvider,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return _buildFullScreenVideo(context, animation, controllerProvider);
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final controllerProvider = _ChewieControllerProvider(
      controller: widget.controller,
      child: ChangeNotifierProvider<PlayerNotifier>.value(
        value: notifier,
        builder: (context, w) => const PlayerWithControls(),
      ),
    );

    if (widget.controller.routePageBuilder == null) {
      return _defaultRoutePageBuilder(context, animation, secondaryAnimation, controllerProvider);
    }
    return widget.controller.routePageBuilder!(context, animation, secondaryAnimation, controllerProvider);
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    onEnterFullScreen();

    if (!widget.controller.allowedScreenSleep) {
      Wakelock.enable();
    }

    await Navigator.of(context, rootNavigator: true).push(route);
    _isFullScreen = false;
    widget.controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    Wakelock.disable();

    SystemChrome.setEnabledSystemUIOverlays(widget.controller.systemOverlaysAfterFullScreen);
    SystemChrome.setPreferredOrientations(widget.controller.deviceOrientationsAfterFullScreen);
  }

  void onEnterFullScreen() {
    final videoWidth = widget.controller.videoPlayerController.value.size.width;
    final videoHeight = widget.controller.videoPlayerController.value.size.height;

    if (widget.controller.systemOverlaysOnEnterFullScreen != null) {
      /// Optional user preferred settings
      SystemChrome.setEnabledSystemUIOverlays(widget.controller.systemOverlaysOnEnterFullScreen!);
    } else {
      /// Default behavior
      SystemChrome.setEnabledSystemUIOverlays([]);
    }

    if (widget.controller.deviceOrientationsOnEnterFullScreen != null) {
      /// Optional user preferred settings
      SystemChrome.setPreferredOrientations(widget.controller.deviceOrientationsOnEnterFullScreen!);
    } else {
      final isLandscapeVideo = videoWidth > videoHeight;
      final isPortraitVideo = videoWidth < videoHeight;

      /// Default behavior
      /// Video w > h means we force landscape
      if (isLandscapeVideo) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }

      /// Video h > w means we force portrait
      else if (isPortraitVideo) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }

      /// Otherwise if h == w (square video)
      else {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }
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
class ChewieController extends ChangeNotifier {
  ChewieController({
    required this.videoPlayerController,
    this.optionsTranslation,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    this.cupertinoProgressColors,
    this.materialProgressColors,
    this.placeholder,
    this.overlay,
    this.showControlsOnInitialize = true,
    this.showOptions = false,
    this.showSubtitleToggle = false,
    this.optionsBuilder,
    this.additionalOptions,
    this.showControls = true,
    this.subtitle,
    this.subtitleBuilder,
    this.customControls,
    this.errorBuilder,
    this.allowedScreenSleep = true,
    this.isLive = false,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.allowPlaybackSpeedChanging = false,
    this.showCupertinoSkipOptions = false,
    this.playbackSpeeds = const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2],
    this.systemOverlaysOnEnterFullScreen,
    this.deviceOrientationsOnEnterFullScreen,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = DeviceOrientation.values,
    this.routePageBuilder,
  }) : assert(playbackSpeeds.every((speed) => speed > 0), 'The playbackSpeeds values must all be greater than 0') {
    _initialize();
  }

  ChewieController copyWith({
    VideoPlayerController? videoPlayerController,
    OptionsTranslation? optionsTranslation,
    double? aspectRatio,
    bool? autoInitialize,
    bool? autoPlay,
    Duration? startAt,
    bool? looping,
    bool? fullScreenByDefault,
    ChewieProgressColors? cupertinoProgressColors,
    ChewieProgressColors? materialProgressColors,
    Widget? placeholder,
    Widget? overlay,
    bool? showControlsOnInitialize,
    bool? showOptions,
    bool? showSubtitleToggle,
    bool? showCupertinoSkipOptions,
    Future<void> Function(BuildContext, List<OptionItem>)? optionsBuilder,
    List<OptionItem> Function(BuildContext)? additionalOptions,
    bool? showControls,
    Subtitles? subtitle,
    Widget Function(BuildContext, dynamic)? subtitleBuilder,
    Widget? customControls,
    Widget Function(BuildContext, String)? errorBuilder,
    bool? allowedScreenSleep,
    bool? isLive,
    bool? allowFullScreen,
    bool? allowMuting,
    bool? allowPlaybackSpeedChanging,
    List<double>? playbackSpeeds,
    List<SystemUiOverlay>? systemOverlaysOnEnterFullScreen,
    List<DeviceOrientation>? deviceOrientationsOnEnterFullScreen,
    List<SystemUiOverlay>? systemOverlaysAfterFullScreen,
    List<DeviceOrientation>? deviceOrientationsAfterFullScreen,
    Widget Function(BuildContext, Animation<double>, Animation<double>, _ChewieControllerProvider)? routePageBuilder,
  }) {
    return ChewieController(
      videoPlayerController: videoPlayerController ?? this.videoPlayerController,
      optionsTranslation: optionsTranslation ?? this.optionsTranslation,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      autoInitialize: autoInitialize ?? this.autoInitialize,
      autoPlay: autoPlay ?? this.autoPlay,
      startAt: startAt ?? this.startAt,
      looping: looping ?? this.looping,
      fullScreenByDefault: fullScreenByDefault ?? this.fullScreenByDefault,
      cupertinoProgressColors: cupertinoProgressColors ?? this.cupertinoProgressColors,
      materialProgressColors: materialProgressColors ?? this.materialProgressColors,
      placeholder: placeholder ?? this.placeholder,
      overlay: overlay ?? this.overlay,
      showControlsOnInitialize: showControlsOnInitialize ?? this.showControlsOnInitialize,
      showOptions: showOptions ?? this.showOptions,
      optionsBuilder: optionsBuilder ?? this.optionsBuilder,
      additionalOptions: additionalOptions ?? this.additionalOptions,
      showControls: showControls ?? this.showControls,
      subtitle: subtitle ?? this.subtitle,
      subtitleBuilder: subtitleBuilder ?? this.subtitleBuilder,
      customControls: customControls ?? this.customControls,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      allowedScreenSleep: allowedScreenSleep ?? this.allowedScreenSleep,
      isLive: isLive ?? this.isLive,
      allowFullScreen: allowFullScreen ?? this.allowFullScreen,
      allowMuting: allowMuting ?? this.allowMuting,
      allowPlaybackSpeedChanging: allowPlaybackSpeedChanging ?? this.allowPlaybackSpeedChanging,
      playbackSpeeds: playbackSpeeds ?? this.playbackSpeeds,
      systemOverlaysOnEnterFullScreen: systemOverlaysOnEnterFullScreen ?? this.systemOverlaysOnEnterFullScreen,
      deviceOrientationsOnEnterFullScreen:
          deviceOrientationsOnEnterFullScreen ?? this.deviceOrientationsOnEnterFullScreen,
      systemOverlaysAfterFullScreen: systemOverlaysAfterFullScreen ?? this.systemOverlaysAfterFullScreen,
      deviceOrientationsAfterFullScreen: deviceOrientationsAfterFullScreen ?? this.deviceOrientationsAfterFullScreen,
      routePageBuilder: routePageBuilder ?? this.routePageBuilder,
      showSubtitleToggle: showSubtitleToggle ?? this.showSubtitleToggle,
      showCupertinoSkipOptions: showCupertinoSkipOptions ?? this.showCupertinoSkipOptions,
    );
  }

  /// If false, the options button in MaterialUI and MaterialDesktopUI
  /// won't be shown.
  final bool showOptions;

  /// If false, the subtitle button in
  /// won't be shown.
  final bool showSubtitleToggle;

  /// If false, the skip button in Cupertino
  /// won't be shown.
  final bool showCupertinoSkipOptions;

  /// Pass your translations for the options like:
  /// - PlaybackSpeed
  /// - Subtitles
  /// - Cancel
  ///
  /// Buttons
  ///
  /// These are required for the default `OptionItem`'s
  final OptionsTranslation? optionsTranslation;

  /// Build your own options with default chewieOptions shiped through
  /// the builder method. Just add your own options to the Widget
  /// you'll build. If you want to hide the chewieOptions, just leave them
  /// out from your Widget.
  final Future<void> Function(BuildContext context, List<OptionItem> chewieOptions)? optionsBuilder;

  /// Add your own additional options on top of chewie options
  final List<OptionItem> Function(BuildContext context)? additionalOptions;

  /// Define here your own Widget on how your n'th subtitle will look like
  final Widget Function(BuildContext context, dynamic subtitle)? subtitleBuilder;

  /// Add a List of Subtitles here in `Subtitles.subtitle`
  Subtitles? subtitle;

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

  /// Weather or not to show the controls when initializing the widget.
  final bool showControlsOnInitialize;

  /// Whether or not to show the controls at all
  final bool showControls;

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget? customControls;

  /// When the video playback runs into an error, you can build a custom
  /// error message.
  final Widget Function(BuildContext context, String errorMessage)? errorBuilder;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  final double? aspectRatio;

  /// The colors to use for controls on iOS. By default, the iOS player uses
  /// colors sampled from the original iOS 11 designs.
  final ChewieProgressColors? cupertinoProgressColors;

  /// The colors to use for the Material Progress Bar. By default, the Material
  /// player uses the colors from your Theme.
  final ChewieProgressColors? materialProgressColors;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget? placeholder;

  /// A widget which is placed between the video and the controls
  final Widget? overlay;

  /// Defines if the player will start in fullscreen when play is pressed
  final bool fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  final bool allowedScreenSleep;

  /// Defines if the controls should be for live stream video
  final bool isLive;

  /// Defines if the fullscreen control should be shown
  final bool allowFullScreen;

  /// Defines if the mute control should be shown
  final bool allowMuting;

  /// Defines if the playback speed control should be shown
  final bool allowPlaybackSpeedChanging;

  /// Defines the set of allowed playback speeds user can change
  final List<double> playbackSpeeds;

  /// Defines the system overlays visible on entering fullscreen
  final List<SystemUiOverlay>? systemOverlaysOnEnterFullScreen;

  /// Defines the set of allowed device orientations on entering fullscreen
  final List<DeviceOrientation>? deviceOrientationsOnEnterFullScreen;

  /// Defines the system overlays visible after exiting fullscreen
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// Defines a custom RoutePageBuilder for the fullscreen
  final ChewieRoutePageBuilder? routePageBuilder;

  static ChewieController of(BuildContext context) {
    final chewieControllerProvider = context.dependOnInheritedWidgetOfExactType<_ChewieControllerProvider>()!;

    return chewieControllerProvider.controller;
  }

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  bool get isPlaying => videoPlayerController.value.isPlaying;

  Future _initialize() async {
    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) && !videoPlayerController.value.isInitialized) {
      await videoPlayerController.initialize();
    }

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }

      await videoPlayerController.play();
    }

    if (startAt != null) {
      await videoPlayerController.seekTo(startAt!);
    }

    if (fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
  }

  Future<void> _fullScreenListener() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  void exitFullScreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
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

  void setSubtitle(List<Subtitle> newSubtitle) {
    subtitle = Subtitles(newSubtitle);
  }
}

class _ChewieControllerProvider extends InheritedWidget {
  const _ChewieControllerProvider({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  final ChewieController controller;

  @override
  bool updateShouldNotify(_ChewieControllerProvider old) => controller != old.controller;
}
