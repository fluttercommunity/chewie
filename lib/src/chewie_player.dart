import 'dart:async';

import 'package:chewie/src/cast/cast_connection_state.dart';
import 'package:chewie/src/cast/cast_device.dart';
import 'package:chewie/src/cast/cast_media.dart';
import 'package:chewie/src/cast/chewie_cast_controller.dart';
import 'package:chewie/src/cast/chewie_playback_target.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/models/chewie_chapter.dart';
import 'web_fullscreen.dart';
import 'package:chewie/src/models/cast_translations.dart';
import 'package:chewie/src/models/option_item.dart';
import 'package:chewie/src/models/options_translation.dart';
import 'package:chewie/src/models/subtitle_model.dart';
import 'package:chewie/src/models/subtitle_style.dart';
import 'package:chewie/src/models/video_quality.dart';
import 'package:chewie/src/notifiers/player_notifier.dart';
import 'package:chewie/src/player_with_controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

typedef ChewieRoutePageBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      ChewieControllerProvider controllerProvider,
    );

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. Chewie wraps it in a friendly skin to
/// make it easy to use!
class Chewie extends StatefulWidget {
  const Chewie({super.key, required this.controller});

  /// The [ChewieController]
  final ChewieController controller;

  @override
  ChewieState createState() {
    return ChewieState();
  }
}

class ChewieState extends State<Chewie> {
  bool _isFullScreen = false;
  bool _wasPlayingBeforeFullScreen = false;
  bool _resumeAppliedInFullScreen = false;

  bool get isControllerFullScreen => widget.controller.isFullScreen;
  late PlayerNotifier notifier;
  late final void Function() _browserFsExitHandler;

  /// Forces the video-element branch on or off, for tests.
  ///
  /// [kIsWeb] is a compile-time constant, so the branch below is unreachable
  /// from a VM test without an override, in the spirit of
  /// `debugDefaultTargetPlatformOverride`. Reset it to null when done.
  @visibleForTesting
  static bool? debugUsesVideoElementFullScreen;

  /// Browsers without the Fullscreen API (iPhone Safari) cannot host the
  /// fullscreen route: `requestFullscreen` throws before the route is pushed,
  /// and the next exit request pops the page underneath instead. On those
  /// browsers the video element's own player is used and no route is involved.
  bool get _usesVideoElementFullScreen =>
      debugUsesVideoElementFullScreen ??
      (kIsWeb &&
          widget.controller.useNativeFullScreenOnWeb &&
          !browserFullscreenSupported);

  // ignore: invalid_use_of_visible_for_testing_member
  int get _playerId => widget.controller.videoPlayerController.playerId;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
    notifier = PlayerNotifier.init();
    // When the user presses Escape, the browser exits its native fullscreen
    // without Chewie knowing. Detect this and collapse the fullscreen route.
    _browserFsExitHandler = () {
      if (!browserInFullscreen && _isFullScreen) {
        widget.controller.exitFullScreen();
      }
    };
    if (widget.controller.useNativeFullScreenOnWeb) {
      addBrowserFullscreenChangeListener(_browserFsExitHandler);
    }
  }

  @override
  void dispose() {
    if (widget.controller.useNativeFullScreenOnWeb) {
      removeBrowserFullscreenChangeListener(_browserFsExitHandler);
    }
    if (_usesVideoElementFullScreen) {
      disposeVideoElementFullscreen(_playerId);
    }
    widget.controller.removeListener(listener);
    notifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Chewie oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(listener);
      widget.controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
    if (_isFullScreen != isControllerFullScreen) {
      widget.controller._isFullScreen = _isFullScreen;
    }
  }

  Future<void> listener() async {
    if (widget.controller.disableFullScreenRoute) {
      // The host app owns the fullscreen presentation; never push/pop a route
      // (which on web reparents the <video> element and forces an HLS reload on
      // exit). Just mirror the controller's flag so the control icon updates.
      _isFullScreen = isControllerFullScreen;
      return;
    }
    if (_usesVideoElementFullScreen) {
      _isFullScreen = isControllerFullScreen;
      if (_isFullScreen) {
        enterVideoElementFullscreen(
          _playerId,
          widget.controller.exitFullScreen,
        );
      } else {
        exitVideoElementFullscreen(_playerId);
      }
      return;
    }
    if (isControllerFullScreen && !_isFullScreen) {
      _wasPlayingBeforeFullScreen =
          widget.controller.videoPlayerController.value.isPlaying;
      _resumeAppliedInFullScreen = false;
      _isFullScreen = isControllerFullScreen;
      await _pushFullScreenWidget(context);
    } else if (!isControllerFullScreen && _isFullScreen) {
      Navigator.of(
        context,
        rootNavigator: widget.controller.useRootNavigator,
      ).pop();
      _isFullScreen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChewieControllerProvider(
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
    ChewieControllerProvider controllerProvider,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: widget.controller.swipeToExitFullscreen
          ? GestureDetector(
              onVerticalDragEnd: (DragEndDetails details) {
                // A positive dy indicates a downward swipe. Use a threshold to avoid accidental triggers.
                final double dy = details.primaryVelocity ?? 0;
                if (dy > widget.controller.swipeThreshold) {
                  widget.controller.exitFullScreen();
                }
              },
              child: Container(
                alignment: Alignment.center,
                color: Colors.black,
                child: controllerProvider,
              ),
            )
          : Container(
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
    ChewieControllerProvider controllerProvider,
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
    final controllerProvider = ChewieControllerProvider(
      controller: widget.controller,
      child: ChangeNotifierProvider<PlayerNotifier>.value(
        value: notifier,
        builder: (context, w) => const PlayerWithControls(),
      ),
    );

    if (kIsWeb && !_resumeAppliedInFullScreen) {
      _resumeAppliedInFullScreen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final vpc = widget.controller.videoPlayerController;
        await vpc.pause();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (_wasPlayingBeforeFullScreen) {
          await vpc.play();
        } else {
          await vpc.play();
          await vpc.pause();
        }
      });
    }

    if (widget.controller.routePageBuilder == null) {
      return _defaultRoutePageBuilder(
        context,
        animation,
        secondaryAnimation,
        controllerProvider,
      );
    }
    return widget.controller.routePageBuilder!(
      context,
      animation,
      secondaryAnimation,
      controllerProvider,
    );
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    onEnterFullScreen();

    if (!widget.controller.allowedScreenSleep) {
      WakelockPlus.enable();
    }

    // Ask the browser to enter its native fullscreen. Must be called before the
    // first await so we are still inside the user-gesture event handler.
    if (widget.controller.useNativeFullScreenOnWeb) {
      requestBrowserFullscreen();
    }

    await Navigator.of(
      context,
      rootNavigator: widget.controller.useRootNavigator,
    ).push(route);

    final wasPlaying = widget.controller.videoPlayerController.value.isPlaying;

    if (kIsWeb) {
      await _reInitializeControllers(wasPlaying);
      // Exit native browser fullscreen when the Chewie route pops (e.g. user
      // clicked the fullscreen button again). No-op if Escape was already used.
      if (widget.controller.useNativeFullScreenOnWeb) {
        exitBrowserFullscreen();
      }
    }

    _isFullScreen = false;
    widget.controller.exitFullScreen();

    if (!widget.controller.allowedScreenSleep) {
      WakelockPlus.disable();
    }

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: widget.controller.systemOverlaysAfterFullScreen,
    );
    SystemChrome.setPreferredOrientations(
      widget.controller.deviceOrientationsAfterFullScreen,
    );
  }

  void onEnterFullScreen() {
    final videoWidth = widget.controller.videoPlayerController.value.size.width;
    final videoHeight =
        widget.controller.videoPlayerController.value.size.height;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    // if (widget.controller.systemOverlaysOnEnterFullScreen != null) {
    //   /// Optional user preferred settings
    //   SystemChrome.setEnabledSystemUIMode(
    //     SystemUiMode.manual,
    //     overlays: widget.controller.systemOverlaysOnEnterFullScreen,
    //   );
    // } else {
    //   /// Default behavior
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    // }

    if (widget.controller.deviceOrientationsOnEnterFullScreen != null) {
      /// Optional user preferred settings
      SystemChrome.setPreferredOrientations(
        widget.controller.deviceOrientationsOnEnterFullScreen!,
      );
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

  /// When viewing full screen on web, returning from full screen could cause
  /// the original video element to lose the picture. We re-initialize the
  /// controllers for web only when returning from full screen and preserve
  /// the previous play/pause state.
  Future<void> _reInitializeControllers(bool wasPlaying) async {
    final prevPosition = widget.controller.videoPlayerController.value.position;

    await widget.controller.videoPlayerController.initialize();
    widget.controller._initialize();
    await widget.controller.videoPlayerController.seekTo(prevPosition);

    if (wasPlaying) {
      await widget.controller.videoPlayerController.play();
    } else {
      await widget.controller.videoPlayerController.play();
      await widget.controller.videoPlayerController.pause();
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
    required this._videoPlayerController,
    this.optionsTranslation,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.draggableProgressBar = true,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    this.cupertinoProgressColors,
    this.materialProgressColors,
    this.materialSeekButtonFadeDuration = const Duration(milliseconds: 300),
    this.materialSeekButtonSize = 26,
    this.placeholder,
    this.overlay,
    this.showControlsOnInitialize = true,
    this.showOptions = true,
    this.optionsBuilder,
    this.additionalOptions,
    this.showControls = true,
    this.showPlayButton = true,
    this.transformationController,
    this.zoomAndPan = false,
    this.maxScale = 2.5,
    this.subtitle,
    this.showSubtitles = false,
    this.subtitleBuilder,
    this.subtitleStyle = const SubtitleStyle(),
    this.customControls,
    this.errorBuilder,
    this.bufferingBuilder,
    this.allowedScreenSleep = true,
    this.isLive = false,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.allowPlaybackSpeedChanging = true,
    this.useRootNavigator = true,
    this.useNativeFullScreenOnWeb = true,
    this.disableFullScreenRoute = false,
    this.playbackSpeeds = const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2],
    this.systemOverlaysOnEnterFullScreen,
    this.deviceOrientationsOnEnterFullScreen,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = DeviceOrientation.values,
    this.routePageBuilder,
    this.progressIndicatorDelay,
    this.hideControlsTimer = defaultHideControlsTimer,
    this.controlsSafeAreaMinimum = EdgeInsets.zero,
    this.pauseOnBackgroundTap = false,
    this.chapters = const [],
    this.castController,
    this.externalPlayback,
    this.castMedia,
    this.allowCasting = true,
    this.castTranslations = const CastTranslations(),
    this.castOverlayBuilder,
    this.additionalControls,
    this.hideCursorInFullScreen = true,
    this.swipeToExitFullscreen = true,
    this.swipeThreshold = 300,
    this.showSeekIndicator = true,
    this.keyboardSeekDuration = const Duration(seconds: 10),
    this.videoQualities = const <VideoQuality>[],
    this.activeVideoQualityId,
    this.onVideoQualityChanged,
  }) : assert(
         playbackSpeeds.every((speed) => speed > 0),
         'The playbackSpeeds values must all be greater than 0',
       ),
       assert(
         _chaptersAreSortedByStart(chapters),
         'The chapters must be sorted by ascending start time',
       ),
       assert(
         castController == null || castMedia != null,
         'A castMedia is required when a castController is set: Chewie cannot '
         'derive a URL the receiver can reach from the local data source.',
       ) {
    _initialize();
  }

  ChewieController copyWith({
    VideoPlayerController? videoPlayerController,
    OptionsTranslation? optionsTranslation,
    double? aspectRatio,
    bool? autoInitialize,
    bool? autoPlay,
    bool? draggableProgressBar,
    Duration? startAt,
    bool? looping,
    bool? fullScreenByDefault,
    ChewieProgressColors? cupertinoProgressColors,
    ChewieProgressColors? materialProgressColors,
    Duration? materialSeekButtonFadeDuration,
    double? materialSeekButtonSize,
    Widget? placeholder,
    Widget? overlay,
    bool? showControlsOnInitialize,
    bool? showOptions,
    Future<void> Function(BuildContext, List<OptionItem>)? optionsBuilder,
    List<OptionItem> Function(BuildContext)? additionalOptions,
    bool? showControls,
    bool? showPlayButton,
    TransformationController? transformationController,
    bool? zoomAndPan,
    double? maxScale,
    Subtitles? subtitle,
    bool? showSubtitles,
    Widget Function(BuildContext, dynamic)? subtitleBuilder,
    SubtitleStyle? subtitleStyle,
    Widget? customControls,
    WidgetBuilder? bufferingBuilder,
    Widget Function(BuildContext, String)? errorBuilder,
    bool? allowedScreenSleep,
    bool? isLive,
    bool? allowFullScreen,
    bool? allowMuting,
    bool? allowPlaybackSpeedChanging,
    bool? useRootNavigator,
    bool? useNativeFullScreenOnWeb,
    bool? disableFullScreenRoute,
    Duration? hideControlsTimer,
    EdgeInsets? controlsSafeAreaMinimum,
    List<double>? playbackSpeeds,
    List<SystemUiOverlay>? systemOverlaysOnEnterFullScreen,
    List<DeviceOrientation>? deviceOrientationsOnEnterFullScreen,
    List<SystemUiOverlay>? systemOverlaysAfterFullScreen,
    List<DeviceOrientation>? deviceOrientationsAfterFullScreen,
    Duration? progressIndicatorDelay,
    Widget Function(
      BuildContext,
      Animation<double>,
      Animation<double>,
      ChewieControllerProvider,
    )?
    routePageBuilder,
    bool? pauseOnBackgroundTap,
    List<ChewieChapter>? chapters,
    ChewieCastController? castController,
    ValueListenable<bool>? externalPlayback,
    CastMedia? castMedia,
    bool? allowCasting,
    CastTranslations? castTranslations,
    Widget Function(BuildContext, CastDevice?)? castOverlayBuilder,
    List<Widget> Function(BuildContext)? additionalControls,
    bool? hideCursorInFullScreen,
    bool? swipeToExitFullscreen,
    double? swipeThreshold,
    bool? showSeekIndicator,
    Duration? keyboardSeekDuration,
    List<VideoQuality>? videoQualities,
    Object? activeVideoQualityId,
    void Function(VideoQuality quality)? onVideoQualityChanged,
  }) {
    return ChewieController(
      draggableProgressBar: draggableProgressBar ?? this.draggableProgressBar,
      videoPlayerController:
          videoPlayerController ?? this.videoPlayerController,
      optionsTranslation: optionsTranslation ?? this.optionsTranslation,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      autoInitialize: autoInitialize ?? this.autoInitialize,
      autoPlay: autoPlay ?? this.autoPlay,
      startAt: startAt ?? this.startAt,
      looping: looping ?? this.looping,
      fullScreenByDefault: fullScreenByDefault ?? this.fullScreenByDefault,
      cupertinoProgressColors:
          cupertinoProgressColors ?? this.cupertinoProgressColors,
      materialProgressColors:
          materialProgressColors ?? this.materialProgressColors,
      zoomAndPan: zoomAndPan ?? this.zoomAndPan,
      maxScale: maxScale ?? this.maxScale,
      controlsSafeAreaMinimum:
          controlsSafeAreaMinimum ?? this.controlsSafeAreaMinimum,
      transformationController:
          transformationController ?? this.transformationController,
      materialSeekButtonFadeDuration:
          materialSeekButtonFadeDuration ?? this.materialSeekButtonFadeDuration,
      materialSeekButtonSize:
          materialSeekButtonSize ?? this.materialSeekButtonSize,
      placeholder: placeholder ?? this.placeholder,
      overlay: overlay ?? this.overlay,
      showControlsOnInitialize:
          showControlsOnInitialize ?? this.showControlsOnInitialize,
      showOptions: showOptions ?? this.showOptions,
      optionsBuilder: optionsBuilder ?? this.optionsBuilder,
      additionalOptions: additionalOptions ?? this.additionalOptions,
      showControls: showControls ?? this.showControls,
      showPlayButton: showPlayButton ?? this.showPlayButton,
      showSubtitles: showSubtitles ?? this.showSubtitles,
      subtitle: subtitle ?? this.subtitle,
      subtitleBuilder: subtitleBuilder ?? this.subtitleBuilder,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      customControls: customControls ?? this.customControls,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      bufferingBuilder: bufferingBuilder ?? this.bufferingBuilder,
      allowedScreenSleep: allowedScreenSleep ?? this.allowedScreenSleep,
      isLive: isLive ?? this.isLive,
      allowFullScreen: allowFullScreen ?? this.allowFullScreen,
      allowMuting: allowMuting ?? this.allowMuting,
      allowPlaybackSpeedChanging:
          allowPlaybackSpeedChanging ?? this.allowPlaybackSpeedChanging,
      useRootNavigator: useRootNavigator ?? this.useRootNavigator,
      useNativeFullScreenOnWeb:
          useNativeFullScreenOnWeb ?? this.useNativeFullScreenOnWeb,
      disableFullScreenRoute:
          disableFullScreenRoute ?? this.disableFullScreenRoute,
      playbackSpeeds: playbackSpeeds ?? this.playbackSpeeds,
      systemOverlaysOnEnterFullScreen:
          systemOverlaysOnEnterFullScreen ??
          this.systemOverlaysOnEnterFullScreen,
      deviceOrientationsOnEnterFullScreen:
          deviceOrientationsOnEnterFullScreen ??
          this.deviceOrientationsOnEnterFullScreen,
      systemOverlaysAfterFullScreen:
          systemOverlaysAfterFullScreen ?? this.systemOverlaysAfterFullScreen,
      deviceOrientationsAfterFullScreen:
          deviceOrientationsAfterFullScreen ??
          this.deviceOrientationsAfterFullScreen,
      routePageBuilder: routePageBuilder ?? this.routePageBuilder,
      hideControlsTimer: hideControlsTimer ?? this.hideControlsTimer,
      progressIndicatorDelay:
          progressIndicatorDelay ?? this.progressIndicatorDelay,
      pauseOnBackgroundTap: pauseOnBackgroundTap ?? this.pauseOnBackgroundTap,
      chapters: chapters ?? this.chapters,
      castController: castController ?? this.castController,
      externalPlayback: externalPlayback ?? this.externalPlayback,
      castMedia: castMedia ?? this.castMedia,
      allowCasting: allowCasting ?? this.allowCasting,
      castTranslations: castTranslations ?? this.castTranslations,
      castOverlayBuilder: castOverlayBuilder ?? this.castOverlayBuilder,
      additionalControls: additionalControls ?? this.additionalControls,
      hideCursorInFullScreen:
          hideCursorInFullScreen ?? this.hideCursorInFullScreen,
      swipeToExitFullscreen:
          swipeToExitFullscreen ?? this.swipeToExitFullscreen,
      swipeThreshold: swipeThreshold ?? this.swipeThreshold,
      showSeekIndicator: showSeekIndicator ?? this.showSeekIndicator,
      keyboardSeekDuration: keyboardSeekDuration ?? this.keyboardSeekDuration,
      videoQualities: videoQualities ?? this.videoQualities,
      activeVideoQualityId: activeVideoQualityId ?? this.activeVideoQualityId,
      onVideoQualityChanged:
          onVideoQualityChanged ?? this.onVideoQualityChanged,
    );
  }

  static const defaultHideControlsTimer = Duration(seconds: 3);

  /// If false, the options button in MaterialUI and MaterialDesktopUI
  /// won't be shown.
  final bool showOptions;

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
  final Future<void> Function(
    BuildContext context,
    List<OptionItem> chewieOptions,
  )?
  optionsBuilder;

  /// Add your own additional options on top of chewie options
  final List<OptionItem> Function(BuildContext context)? additionalOptions;

  /// Define here your own Widget on how your n'th subtitle will look like
  ///
  /// Receives the cue exactly as it was supplied, markup and all. Chewie's own
  /// rendering — including [SubtitleStyle] and markup parsing — is skipped
  /// entirely. To keep markup while building your own widget, run the cue
  /// through `parseSubtitleMarkup` yourself.
  Widget Function(BuildContext context, dynamic subtitle)? subtitleBuilder;

  /// Add a List of Subtitles here in `Subtitles.subtitle`
  Subtitles? subtitle;

  /// How the default subtitle box looks: text style, alignment, padding and
  /// the box behind the text.
  ///
  /// Cue markup such as `<i>` is rendered whatever this is set to, so styling
  /// subtitles does not cost you italics. Ignored when [subtitleBuilder] is
  /// set.
  SubtitleStyle subtitleStyle;

  /// Determines whether subtitles should be shown by default when the video starts.
  ///
  /// If set to `true`, subtitles will be displayed automatically when the video
  /// begins playing. If set to `false`, subtitles will be hidden by default.
  bool showSubtitles;

  /// The controller for the video you want to play.
  ///
  /// Replaced by [swapVideoSource]; hosts that swap sources should read this
  /// getter (rather than keep their own reference) when disposing.
  VideoPlayerController get videoPlayerController => _videoPlayerController;
  VideoPlayerController _videoPlayerController;

  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Non-Draggable Progress Bar
  final bool draggableProgressBar;

  /// Start video at a certain position
  final Duration? startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// Wether or not to show the controls when initializing the widget.
  final bool showControlsOnInitialize;

  /// Whether or not to show the controls at all
  final bool showControls;

  /// Whether or not to show the center play button.
  /// Only used when [customControls] is not set.
  final bool showPlayButton;

  /// Controller to pass into the [InteractiveViewer] component.
  /// If it is required to control the transformation only via the controller,
  /// `zoomAndPan` should be set to false.
  final TransformationController? transformationController;

  /// Whether or not to allow zooming and panning.
  /// This can still be false, and the `transformationController` can be used to control the
  /// transformation.
  final bool zoomAndPan;

  /// Max scale when zooming
  final double maxScale;

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget? customControls;

  /// When the video playback runs into an error, you can build a custom
  /// error message.
  final Widget Function(BuildContext context, String errorMessage)?
  errorBuilder;

  /// When the video is buffering, you can build a custom widget.
  final WidgetBuilder? bufferingBuilder;

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

  // The duration of the fade animation for the seek button (Material Player only)
  final Duration materialSeekButtonFadeDuration;

  // The size of the seek button for the Material Player only
  final double materialSeekButtonSize;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget? placeholder;

  /// A widget which is placed between the video and the controls
  final Widget? overlay;

  /// Defines if the player will start in fullscreen when play is pressed
  final bool fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  final bool allowedScreenSleep;

  /// Defines if the controls should be shown for live stream video
  final bool isLive;

  /// Defines if the fullscreen control should be shown
  final bool allowFullScreen;

  /// Defines if the mute control should be shown
  final bool allowMuting;

  /// Defines if the playback speed control should be shown
  final bool allowPlaybackSpeedChanging;

  /// Defines if push/pop navigations use the rootNavigator
  final bool useRootNavigator;

  /// On Flutter Web, also enter the browser's native fullscreen (via the
  /// Fullscreen API) when going fullscreen, instead of only expanding the
  /// Flutter view inside the browser window. Pressing Escape to leave the
  /// browser fullscreen also exits Chewie's fullscreen.
  ///
  /// Has no effect on non-web platforms.
  final bool useNativeFullScreenOnWeb;

  /// When true, toggling fullscreen does NOT push/pop Chewie's own fullscreen
  /// route. The controller's [isFullScreen] still flips (so the control icon
  /// updates), but the player widget stays mounted in place and the host app is
  /// responsible for the fullscreen presentation (e.g. driving the browser
  /// Fullscreen API and expanding its own layout).
  ///
  /// On web, Chewie's route-based fullscreen reparents the platform-view
  /// `<video>` element; on exit the original view goes blank and the fork works
  /// around it by re-initializing the controller — which for an HLS source
  /// means a full manifest reload + rebuffer. Setting this avoids that entirely
  /// by never moving the element.
  final bool disableFullScreenRoute;

  /// Defines the [Duration] before the video controls are hidden. By default, this is set to three seconds.
  final Duration hideControlsTimer;

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

  /// Defines a delay in milliseconds between entering buffering state and displaying the loading spinner. Set null (default) to disable it.
  final Duration? progressIndicatorDelay;

  /// Adds additional padding to the controls' [SafeArea] as desired.
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsets controlsSafeAreaMinimum;

  /// Defines if the player should pause when the background is tapped
  final bool pauseOnBackgroundTap;

  /// Chapters of the video, sorted by ascending start time.
  /// When non-empty, the progress bar is split into chapter segments and the
  /// hovered/scrubbed chapter title is displayed above the bar.
  final List<ChewieChapter> chapters;

  static bool _chaptersAreSortedByStart(List<ChewieChapter> chapters) {
    for (var i = 1; i < chapters.length; i++) {
      if (chapters[i].start < chapters[i - 1].start) {
        return false;
      }
    }
    return true;
  }

  /// The cast backend to drive, or null to leave casting off entirely.
  ///
  /// Chewie ships no sender of its own — see [ChewieCastController] for what
  /// implementing one involves. When this is set the control bars grow a cast
  /// button, and connecting hands playback over to the receiver.
  ///
  /// Chewie listens to this controller but never disposes it; the app owns its
  /// lifetime, so a single instance can serve many videos in a row.
  final ChewieCastController? castController;

  /// Whether playback has left this device by some means Chewie does not own.
  ///
  /// A cast session Chewie manages is already covered by [castController].
  /// This is for everything else — AirPlay being the case it was added for,
  /// where the platform routes the same player to a television and there is no
  /// receiver to enumerate, connect to or hand over to, so it cannot be
  /// modelled as a [ChewieCastController] at all.
  ///
  /// Chewie only reads it, to know that the local surface is not what the
  /// viewer is looking at: while it reports true the buffering spinner is
  /// suppressed, because whatever is showing the video reports its own loading
  /// state on the screen the viewer is actually watching.
  ///
  /// Supply anything that can answer the question and say when the answer
  /// changes; `chewie_cast`'s `AirPlayController` is one such thing.
  final ValueListenable<bool>? externalPlayback;

  /// What to play on the receiver. Required whenever [castController] is set.
  ///
  /// The receiver fetches this URL itself, so it has to be reachable from the
  /// TV — which is why Chewie cannot reuse the local data source.
  final CastMedia? castMedia;

  /// Defines if the cast button should be shown. Only has an effect when
  /// [castController] is set.
  final bool allowCasting;

  /// Strings for the casting UI.
  final CastTranslations castTranslations;

  /// Replaces Chewie's default casting overlay — the thing shown in place of
  /// the video while a session is live. Receives the connected device, which
  /// is null in the moment before a session settles.
  final Widget Function(BuildContext context, CastDevice? device)?
  castOverlayBuilder;

  /// Extra widgets for the control bar, beside the built-in buttons.
  ///
  /// Unlike [additionalOptions], which adds rows to the options sheet, these go
  /// into the bar itself — for controls that have to be a widget rather than a
  /// menu entry, such as an AirPlay button.
  ///
  /// They inherit the bar's show/hide behaviour, so they fade with the rest of
  /// the controls rather than sitting on top of the video.
  ///
  /// Two things are worth knowing before putting something here:
  ///
  /// * **Platform views do not work.** A `UiKitView` placed in the control bar
  ///   lays out and receives taps but paints nothing — verified on iOS, where a
  ///   real `AVRoutePickerView` is invisible here while the identical widget
  ///   renders fine as a sibling of the [Chewie] widget. Draw the control in
  ///   Flutter instead.
  /// * **Read [ChewieControlStyle] rather than hard-coding a look.** The skins
  ///   differ — the Cupertino bar is 30 logical pixels tall in portrait with
  ///   16px glyphs on frosted pills, the Material bars are taller with 24px
  ///   icons — so a widget sized for one sits wrong in another. Each skin
  ///   installs its own values above whatever it is given; a control that
  ///   takes its size, tint, padding and chrome from there matches the buttons
  ///   beside it on all three.
  final List<Widget> Function(BuildContext context)? additionalControls;
  /// Selectable video qualities shown in the options menu.
  ///
  /// Source-agnostic: the host populates this and reacts to selection via
  /// [onVideoQualityChanged] — typically by calling [swapVideoSource] with a
  /// controller for the chosen quality, or by switching the rendition of an
  /// adaptive stream. May change after the video loads — use
  /// [setVideoQualities] so the controls rebuild.
  List<VideoQuality> videoQualities;

  /// Id of the currently selected quality in [videoQualities].
  Object? activeVideoQualityId;

  /// Called when the user picks a video quality from the menu.
  final void Function(VideoQuality quality)? onVideoQualityChanged;

  /// Whether more than one selectable video quality is available (a single
  /// quality offers nothing to choose, so the menu entry stays hidden).
  bool get hasVideoQualities => videoQualities.length > 1;

  /// Whether to flash a YouTube-style indicator showing the seeked amount when
  /// seeking with the keyboard arrows on desktop. Repeated presses in the same
  /// direction accumulate (e.g. 10s → 20s → 30s). Defaults to `true`.
  final bool showSeekIndicator;

  /// Defines if the player allows swipe to exit fullscreen
  final bool swipeToExitFullscreen;

  /// Defines the minimum velocity threshold for swipe to exit fullscreen gesture
  /// The velocity is measured in pixels per second
  final double swipeThreshold;

  /// Whether the mouse cursor auto-hides together with the controls while in
  /// fullscreen (and reappears on mouse movement), like most video players.
  /// Has no effect outside fullscreen or on devices without a pointer.
  /// Defaults to `true`.
  final bool hideCursorInFullScreen;

  /// How far each left/right arrow-key press seeks on the desktop controls.
  /// Also drives the amount shown by the seek indicator. Defaults to 10 seconds.
  final Duration keyboardSeekDuration;

  static ChewieController of(BuildContext context) {
    final chewieControllerProvider = context
        .dependOnInheritedWidgetOfExactType<ChewieControllerProvider>()!;

    return chewieControllerProvider.controller;
  }

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  bool get isPlaying => playback.value.isPlaying;

  late final ChewiePlaybackTarget _localPlayback = LocalPlaybackTarget(
    videoPlayerController,
  );
  late final ChewiePlaybackTarget? _castPlayback = castController == null
      ? null
      : CastPlaybackTarget(castController!);

  /// Whether a cast session is currently carrying playback.
  bool get isCasting => castController?.isConnected ?? false;

  /// Whether the video has left this device's screen, or is in the act of
  /// leaving it.
  ///
  /// True for a cast session, for the moments while one is being set up, and
  /// for [externalPlayback] alike. The controls care about one thing here —
  /// whether the local surface is what the viewer is looking at — and from the
  /// instant a device is picked it is not: the casting overlay covers it.
  ///
  /// Connecting counts deliberately. Leaving it out let the controls decorate
  /// a surface the overlay had already replaced: a centre play button drawn on
  /// top of it, and the control bar fading out on its usual timer, taking the
  /// pulsing cast button with it.
  bool get isPlaybackRemote =>
      isCasting ||
      castConnectionState.isTransitioning ||
      (externalPlayback?.value ?? false);

  /// Guards the deferred work in [_initialize] against a controller that was
  /// disposed before the frame it was waiting for.
  bool _disposed = false;

  /// Where the session currently is, or [CastConnectionState.disconnected]
  /// when casting is not configured at all.
  CastConnectionState get castConnectionState =>
      castController?.connectionState ?? CastConnectionState.disconnected;

  /// The receiver playback is on, or null when playing locally.
  CastDevice? get castDevice => castController?.connectedDevice;

  /// Whatever the controls should be driving right now: the local player, or
  /// the receiver while a session is live.
  ///
  /// Listen to this rather than to [videoPlayerController] to follow playback
  /// across a handover — though note the returned object changes identity when
  /// a session starts or ends, so listeners have to be moved with it.
  ChewiePlaybackTarget get playback =>
      isCasting ? _castPlayback! : _localPlayback;

  /// True once Chewie has handed playback to the receiver, so the handover
  /// runs exactly once per session in each direction.
  bool _handedOffToReceiver = false;

  // Sampled while the session is live: some backends reset their value on
  // disconnect, and by the time we need the position to resume locally the
  // session is already gone.
  Duration _lastRemotePosition = Duration.zero;
  bool _lastRemoteWasPlaying = false;

  Future<dynamic> _initialize() async {
    // _initialize runs again when the web fullscreen path re-creates the
    // texture, so make sure we never end up subscribed twice.
    castController?.removeListener(_onCastStateChanged);
    castController?.addListener(_onCastStateChanged);
    externalPlayback?.removeListener(_onExternalPlaybackChanged);
    externalPlayback?.addListener(_onExternalPlaybackChanged);

    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.isInitialized) {
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

    // A session can already be live when this controller is built: senders are
    // owned by the app, so they outlive the screen that created them, and the
    // Cast SDKs keep a session running until it is ended. A listener only
    // fires on a change, so without adopting the state that is already there,
    // opening a second video would play it on the device while the receiver
    // still held the first one.
    //
    // Deferred by a frame because this runs from the constructor, and apps
    // build a ChewieController inside build(): handing over notifies the cast
    // controller, and its listeners would be marked dirty during that build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _onCastStateChanged();
    });
  }

  Future<void> _fullScreenListener() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  /// Moves playback between the device and the receiver as the session opens
  /// and closes.
  ///
  /// Deliberately does not call [notifyListeners]: on this controller that
  /// means "fullscreen changed" and would pop the fullscreen route. Cast UI
  /// rebuilds off [castController]'s own notifications instead.
  /// Nothing to do but rebuild: Chewie does not drive external playback, it
  /// only needs to stop drawing over a surface the viewer is not watching.
  void _onExternalPlaybackChanged() => notifyListeners();

  void _onCastStateChanged() {
    final cast = castController;
    if (cast == null) return;

    final state = cast.connectionState;

    if (state.isConnected) {
      _lastRemotePosition = cast.value.position;
      _lastRemoteWasPlaying = cast.value.isPlaying;

      if (!_handedOffToReceiver) {
        _handedOffToReceiver = true;
        _handOffToReceiver();
      }
    } else if (state.isDisconnected && _handedOffToReceiver) {
      _handedOffToReceiver = false;
      _handBackFromReceiver();
    }
  }

  /// Pauses locally and starts the same moment on the receiver.
  Future<void> _handOffToReceiver() async {
    final cast = castController;
    final media = castMedia;
    if (cast == null || media == null) return;

    final local = videoPlayerController.value;
    final startAt = local.position;
    final wasPlaying = local.isPlaying;

    if (wasPlaying) {
      await videoPlayerController.pause();
    }

    // Nothing to hand over if the receiver already holds this media. Apps
    // rebuild their ChewieController routinely — `copyWith`, switching video —
    // and each new instance starts with _handedOffToReceiver false, so without
    // this the receiver would be told to load what it is already playing and
    // would restart from the local position.
    if (cast.currentMedia == media && cast.value.isInitialized) {
      return;
    }

    await cast.load(media, startAt: startAt, autoPlay: wasPlaying);
  }

  /// Picks local playback back up wherever the receiver left off.
  Future<void> _handBackFromReceiver() async {
    if (!videoPlayerController.value.isInitialized) {
      await videoPlayerController.initialize();
    }

    await videoPlayerController.seekTo(_lastRemotePosition);

    if (_lastRemoteWasPlaying) {
      await videoPlayerController.play();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    // The app owns the cast controller — unsubscribe, but never dispose it.
    castController?.removeListener(_onCastStateChanged);
    externalPlayback?.removeListener(_onExternalPlaybackChanged);
    super.dispose();
  }

  /// Replaces [videoPlayerController] with [newController], preserving the
  /// playback position, speed, volume, looping and play/pause state of the
  /// old controller.
  ///
  /// Use this to switch to another rendition of the current video (e.g. a
  /// different quality) without rebuilding the [ChewieController].
  ///
  /// [newController] is initialized before the swap, so the player never
  /// shows an unready source; if initialization fails, the error is rethrown
  /// and the old controller stays in place. Chewie takes ownership of
  /// [newController]: the old controller is disposed after the UI has
  /// re-attached, and the host's own dispose should read
  /// [videoPlayerController] rather than keep a reference to a controller
  /// created earlier. Pass [disposeOldController] as `false` to keep the old
  /// controller alive instead — for example when swapping between preloaded
  /// controllers the host still owns.
  Future<void> swapVideoSource(
    VideoPlayerController newController, {
    bool disposeOldController = true,
  }) async {
    final oldController = _videoPlayerController;
    final oldValue = oldController.value;

    if (!newController.value.isInitialized) {
      await newController.initialize();
    }
    await newController.setLooping(looping);
    if (oldValue.isInitialized && oldValue.position > Duration.zero) {
      await newController.seekTo(oldValue.position);
    }
    await newController.setPlaybackSpeed(oldValue.playbackSpeed);
    await newController.setVolume(oldValue.volume);
    if (oldValue.isPlaying) {
      await newController.play();
    }

    // No-op unless fullScreenByDefault attached it and it hasn't fired yet.
    oldController.removeListener(_fullScreenListener);
    _videoPlayerController = newController;
    notifyListeners();

    if (disposeOldController) {
      // Wait for the frame triggered by notifyListeners(), so the rebuilt
      // controls have detached their listeners from the old controller.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
      });
    }
  }

  /// Replaces the selectable [videoQualities] and rebuilds the controls.
  ///
  /// Use when qualities become known only after the media loads (e.g. once a
  /// manifest is parsed).
  void setVideoQualities(List<VideoQuality> qualities) {
    videoQualities = qualities;
    notifyListeners();
  }

  /// Selects [quality] as the active one, updating [activeVideoQualityId]
  /// and notifying [onVideoQualityChanged].
  void selectVideoQuality(VideoQuality quality) {
    activeVideoQualityId = quality.id;
    onVideoQualityChanged?.call(quality);
    notifyListeners();
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
    await playback.play();
  }

  // Looping is a local-player concept; receivers manage their own queue, so
  // this stays pointed at the local controller even mid-session.
  // ignore: avoid_positional_boolean_parameters
  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  Future<void> pause() async {
    await playback.pause();
  }

  Future<void> seekTo(Duration moment) async {
    await playback.seekTo(moment);
  }

  Future<void> setVolume(double volume) async {
    await playback.setVolume(volume);
  }

  void setSubtitle(List<Subtitle> newSubtitle) {
    subtitle = Subtitles(newSubtitle);
  }
}

class ChewieControllerProvider extends InheritedWidget {
  const ChewieControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  final ChewieController controller;

  @override
  bool updateShouldNotify(ChewieControllerProvider oldWidget) =>
      controller != oldWidget.controller;
}
