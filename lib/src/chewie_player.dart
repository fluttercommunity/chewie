import 'dart:async';

import 'package:chewie/src/cast/cast_connection_state.dart';
import 'package:chewie/src/cast/cast_device.dart';
import 'package:chewie/src/cast/cast_media.dart';
import 'package:chewie/src/cast/chewie_cast_controller.dart';
import 'package:chewie/src/cast/chewie_playback_target.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'web_fullscreen.dart';
import 'package:chewie/src/models/cast_translations.dart';
import 'package:chewie/src/models/option_item.dart';
import 'package:chewie/src/models/options_translation.dart';
import 'package:chewie/src/models/subtitle_model.dart';
import 'package:chewie/src/models/subtitle_style.dart';
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
    widget.controller.removeListener(listener);
    notifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Chewie oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
    if (_isFullScreen != isControllerFullScreen) {
      widget.controller._isFullScreen = _isFullScreen;
    }
  }

  Future<void> listener() async {
    if (isControllerFullScreen && !_isFullScreen) {
      _wasPlayingBeforeFullScreen =
          widget.controller.videoPlayerController.value.isPlaying;
      _resumeAppliedInFullScreen = false;
      _isFullScreen = isControllerFullScreen;
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
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
    required this.videoPlayerController,
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
    this.castController,
    this.castMedia,
    this.allowCasting = true,
    this.castTranslations = const CastTranslations(),
    this.castOverlayBuilder,
    this.additionalControls,
  }) : assert(
         playbackSpeeds.every((speed) => speed > 0),
         'The playbackSpeeds values must all be greater than 0',
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
    ChewieCastController? castController,
    CastMedia? castMedia,
    bool? allowCasting,
    CastTranslations? castTranslations,
    Widget Function(BuildContext, CastDevice?)? castOverlayBuilder,
    List<Widget> Function(BuildContext)? additionalControls,
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
      castController: castController ?? this.castController,
      castMedia: castMedia ?? this.castMedia,
      allowCasting: allowCasting ?? this.allowCasting,
      castTranslations: castTranslations ?? this.castTranslations,
      castOverlayBuilder: castOverlayBuilder ?? this.castOverlayBuilder,
      additionalControls: additionalControls ?? this.additionalControls,
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

  /// The controller for the video you want to play
  final VideoPlayerController videoPlayerController;

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

  /// The cast backend to drive, or null to leave casting off entirely.
  ///
  /// Chewie ships no sender of its own — see [ChewieCastController] for what
  /// implementing one involves. When this is set the control bars grow a cast
  /// button, and connecting hands playback over to the receiver.
  ///
  /// Chewie listens to this controller but never disposes it; the app owns its
  /// lifetime, so a single instance can serve many videos in a row.
  final ChewieCastController? castController;

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
  /// menu entry. A platform view is the motivating case: an AirPlay button must
  /// be UIKit's own `AVRoutePickerView`, because Apple exposes no way to select
  /// a route programmatically.
  ///
  /// They inherit the bar's show/hide behaviour, so they fade with the rest of
  /// the controls rather than sitting on top of the video.
  final List<Widget> Function(BuildContext context)? additionalControls;

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
    // The app owns the cast controller — unsubscribe, but never dispose it.
    castController?.removeListener(_onCastStateChanged);
    super.dispose();
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
