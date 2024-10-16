import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cast_video/flutter_cast_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pip_manager/pip_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../chewie.dart';
import 'audio_controls.dart';
import 'helpers/models/audio_track.dart';
import 'helpers/models/video_track.dart';
import 'notifiers/player_notifier.dart';
import 'player_with_controls.dart';

typedef ChewieRoutePageBuilder = Widget Function(
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
  const Chewie({
    required this.controller,
    super.key,
  });

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

  bool get isControllerFullScreen => widget.controller.isFullScreen;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
    notifier = PlayerNotifier.init();
  }

  @override
  void dispose() {
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
      await WakelockPlus.enable();
    }

    await Navigator.of(
      context,
      rootNavigator: widget.controller.useRootNavigator,
    ).push(route);

    _isFullScreen = false;
    widget.controller.exitFullScreen();

    if (!widget.controller.allowedScreenSleep) {
      await WakelockPlus.disable();
    }

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: widget.controller.systemOverlaysAfterFullScreen,
    );
    await SystemChrome.setPreferredOrientations(
      widget.controller.deviceOrientationsAfterFullScreen,
    );
  }

  void onEnterFullScreen() {
    final videoWidth = widget.controller.videoPlayerController.value.size.width;
    final videoHeight =
        widget.controller.videoPlayerController.value.size.height;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

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
}

class MediaControls {
  MediaControls({
    this.onNext,
    this.onPrev,
    this.onOpen,
  });

  VoidCallback? onNext;
  VoidCallback? onPrev;
  VoidCallback? onOpen;
}

class MediaThumbnail {
  const MediaThumbnail({
    required this.medium,
    required this.large,
  });

  final String? medium;
  final String? large;
}

class MediaChromeCast {
  const MediaChromeCast({
    required this.onSessionStarted,
  });

  final FutureOr<String> Function() onSessionStarted;
}

class MediaDescription {
  const MediaDescription({
    this.subtitle,
    this.artist,
    this.poster,
    this.album,
    this.title,
  });

  final String? title;
  final String? album;
  final String? artist;
  final String? poster;
  final String? subtitle;
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
    required VideoPlayerController videoPlayerController,
    double? aspectRatio,
    BoxFit? fit,
    HlsDownloaded? hlsMaster,
    this.optionsTranslation,
    this.thumbnails,
    this.chromeCast,
    this.mediaControls,
    this.directory,
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
    this.subtitleBuilder,
    this.description,
    this.customControls,
    this.errorBuilder,
    this.bufferingBuilder,
    this.allowedScreenSleep = false,
    this.isLive = false,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.allowPlaybackSpeedChanging = true,
    this.useRootNavigator = true,
    this.playbackSpeeds = const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2],
    this.systemOverlaysOnEnterFullScreen,
    this.deviceOrientationsOnEnterFullScreen,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = DeviceOrientation.values,
    this.routePageBuilder,
    this.progressIndicatorDelay,
    this.hideControlsTimer = defaultHideControlsTimer,
    this.controlsSafeAreaMinimum = EdgeInsets.zero,
    this.server,
  }) : assert(
          playbackSpeeds.every((speed) => speed > 0),
          'The playbackSpeeds values must all be greater than 0',
        ) {
    _aspectRatio = aspectRatio;
    _fit.value = fit ?? _fit.value;
    _hlsMaster = hlsMaster;
    _videoPlayerController = videoPlayerController;
    _initialize();
    _initializeSpeed();
    _videoPlayerController.addListener(_listenerSpeed);
  }

  static Future<ChewieController> fromHlsUrl({
    required String url,
    MediaDescription? description,
    MediaChromeCast? chromeCast,
    Map<String, dynamic>? headers,
    MediaControls? mediaControls,
    MediaThumbnail? thumbnails,
    Directory? directory,
    OptionsTranslation? optionsTranslation,
    double? aspectRatio,
    BoxFit? fit,
    bool autoInitialize = false,
    bool autoPlay = false,
    bool draggableProgressBar = true,
    Duration? startAt,
    bool looping = false,
    bool fullScreenByDefault = false,
    ChewieProgressColors? cupertinoProgressColors,
    ChewieProgressColors? materialProgressColors,
    Duration materialSeekButtonFadeDuration = const Duration(
      milliseconds: 300,
    ),
    double materialSeekButtonSize = 26,
    Widget? placeholder,
    Widget? overlay,
    bool showControlsOnInitialize = false,
    bool showOptions = true,
    Future<void> Function(BuildContext, List<OptionItem>)? optionsBuilder,
    List<OptionItem> Function(BuildContext)? additionalOptions,
    bool showControls = true,
    TransformationController? transformationController,
    bool zoomAndPan = false,
    double maxScale = 2.5,
    Subtitles? subtitle,
    Widget Function(BuildContext, dynamic)? subtitleBuilder,
    Widget? customControls,
    WidgetBuilder? bufferingBuilder,
    Widget Function(BuildContext, String)? errorBuilder,
    bool allowedScreenSleep = false,
    bool isLive = false,
    bool allowFullScreen = true,
    bool allowMuting = true,
    bool allowPlaybackSpeedChanging = true,
    bool useRootNavigator = true,
    Duration hideControlsTimer = defaultHideControlsTimer,
    EdgeInsets controlsSafeAreaMinimum = EdgeInsets.zero,
    List<double> playbackSpeeds = const [
      0.25,
      0.5,
      0.75,
      1,
      1.25,
      1.5,
      1.75,
      2,
    ],
    List<SystemUiOverlay>? systemOverlaysOnEnterFullScreen,
    List<DeviceOrientation>? deviceOrientationsOnEnterFullScreen,
    List<SystemUiOverlay> systemOverlaysAfterFullScreen =
        SystemUiOverlay.values,
    List<DeviceOrientation> deviceOrientationsAfterFullScreen =
        DeviceOrientation.values,
    Duration? progressIndicatorDelay,
    Widget Function(
      BuildContext,
      Animation<double>,
      Animation<double>,
      ChewieControllerProvider,
    )? routePageBuilder,
  }) async {
    final initialDirectory = directory ?? await getTemporaryDirectory();

    final downloadManager = HlsDownloadManager(
      initialDirectory,
    );

    final downloaded = await downloadManager.downloadHlsFromUrl(
      url: url,
      headers: headers,
    );

    final masterPath =
        downloaded.master.path.replaceFirst('${initialDirectory.path}/', '');

    final random = Random();
    final randomPort = 1000 + random.nextInt(9000);

    final server = await _startServerForFiles(
      initialDirectory,
      port: randomPort,
    );

    final videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse('http://localhost:$randomPort/$masterPath'),
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: true,
        mixWithOthers: true,
      ),
    );

    return ChewieController(
      chromeCast: chromeCast,
      thumbnails: thumbnails,
      draggableProgressBar: draggableProgressBar,
      videoPlayerController: videoPlayerController,
      optionsTranslation: optionsTranslation,
      aspectRatio: aspectRatio,
      fit: fit,
      directory: initialDirectory,
      autoInitialize: autoInitialize,
      autoPlay: autoPlay,
      startAt: startAt,
      description: description,
      server: server,
      looping: looping,
      maxScale: maxScale,
      mediaControls: mediaControls,
      hlsMaster: downloaded,
      transformationController: transformationController,
      fullScreenByDefault: fullScreenByDefault,
      cupertinoProgressColors: cupertinoProgressColors,
      materialProgressColors: materialProgressColors,
      materialSeekButtonFadeDuration: materialSeekButtonFadeDuration,
      materialSeekButtonSize: materialSeekButtonSize,
      placeholder: placeholder,
      overlay: overlay,
      zoomAndPan: zoomAndPan,
      showControlsOnInitialize: showControlsOnInitialize,
      showOptions: showOptions,
      optionsBuilder: optionsBuilder,
      additionalOptions: additionalOptions,
      showControls: showControls,
      subtitle: subtitle,
      subtitleBuilder: subtitleBuilder,
      customControls: customControls,
      errorBuilder: errorBuilder,
      bufferingBuilder: bufferingBuilder,
      allowedScreenSleep: allowedScreenSleep,
      isLive: isLive,
      allowFullScreen: allowFullScreen,
      allowMuting: allowMuting,
      allowPlaybackSpeedChanging: allowPlaybackSpeedChanging,
      useRootNavigator: useRootNavigator,
      playbackSpeeds: playbackSpeeds,
      controlsSafeAreaMinimum: controlsSafeAreaMinimum,
      systemOverlaysOnEnterFullScreen: systemOverlaysOnEnterFullScreen,
      deviceOrientationsOnEnterFullScreen: deviceOrientationsOnEnterFullScreen,
      systemOverlaysAfterFullScreen: systemOverlaysAfterFullScreen,
      deviceOrientationsAfterFullScreen: deviceOrientationsAfterFullScreen,
      routePageBuilder: routePageBuilder,
      hideControlsTimer: hideControlsTimer,
      progressIndicatorDelay: progressIndicatorDelay,
    );
  }

  ChewieController copyWith({
    MediaDescription? description,
    MediaChromeCast? chromeCast,
    VideoPlayerController? videoPlayerController,
    OptionsTranslation? optionsTranslation,
    MediaControls? mediaControls,
    MediaThumbnail? thumbnails,
    double? aspectRatio,
    HlsDownloaded? hlsMaster,
    Directory? directory,
    BoxFit? fit,
    bool? autoInitialize,
    bool? autoPlay,
    HttpServer? server,
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
    Widget Function(BuildContext, dynamic)? subtitleBuilder,
    Widget? customControls,
    WidgetBuilder? bufferingBuilder,
    Widget Function(BuildContext, String)? errorBuilder,
    bool? allowedScreenSleep,
    bool? isLive,
    bool? allowFullScreen,
    bool? allowMuting,
    bool? allowPlaybackSpeedChanging,
    bool? useRootNavigator,
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
    )? routePageBuilder,
  }) {
    return ChewieController(
      thumbnails: thumbnails ?? this.thumbnails,
      chromeCast: chromeCast ?? this.chromeCast,
      draggableProgressBar: draggableProgressBar ?? this.draggableProgressBar,
      videoPlayerController: videoPlayerController ?? _videoPlayerController,
      optionsTranslation: optionsTranslation ?? this.optionsTranslation,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      fit: fit ?? this.fit.value,
      autoInitialize: autoInitialize ?? this.autoInitialize,
      autoPlay: autoPlay ?? this.autoPlay,
      startAt: startAt ?? this.startAt,
      looping: looping ?? this.looping,
      mediaControls: mediaControls ?? this.mediaControls,
      fullScreenByDefault: fullScreenByDefault ?? this.fullScreenByDefault,
      cupertinoProgressColors:
          cupertinoProgressColors ?? this.cupertinoProgressColors,
      materialProgressColors:
          materialProgressColors ?? this.materialProgressColors,
      materialSeekButtonFadeDuration:
          materialSeekButtonFadeDuration ?? this.materialSeekButtonFadeDuration,
      materialSeekButtonSize:
          materialSeekButtonSize ?? this.materialSeekButtonSize,
      placeholder: placeholder ?? this.placeholder,
      hlsMaster: hlsMaster ?? _hlsMaster,
      server: server ?? this.server,
      description: description ?? this.description,
      directory: directory ?? this.directory,
      overlay: overlay ?? this.overlay,
      showControlsOnInitialize:
          showControlsOnInitialize ?? this.showControlsOnInitialize,
      showOptions: showOptions ?? this.showOptions,
      optionsBuilder: optionsBuilder ?? this.optionsBuilder,
      additionalOptions: additionalOptions ?? this.additionalOptions,
      showControls: showControls ?? this.showControls,
      subtitle: subtitle ?? this.subtitle,
      subtitleBuilder: subtitleBuilder ?? this.subtitleBuilder,
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
      playbackSpeeds: playbackSpeeds ?? this.playbackSpeeds,
      systemOverlaysOnEnterFullScreen: systemOverlaysOnEnterFullScreen ??
          this.systemOverlaysOnEnterFullScreen,
      deviceOrientationsOnEnterFullScreen:
          deviceOrientationsOnEnterFullScreen ??
              this.deviceOrientationsOnEnterFullScreen,
      systemOverlaysAfterFullScreen:
          systemOverlaysAfterFullScreen ?? this.systemOverlaysAfterFullScreen,
      deviceOrientationsAfterFullScreen: deviceOrientationsAfterFullScreen ??
          this.deviceOrientationsAfterFullScreen,
      routePageBuilder: routePageBuilder ?? this.routePageBuilder,
      hideControlsTimer: hideControlsTimer ?? this.hideControlsTimer,
      progressIndicatorDelay:
          progressIndicatorDelay ?? this.progressIndicatorDelay,
    );
  }

  Future<void> _initializeSpeed() async {
    final pref = await SharedPreferences.getInstance();

    final speed = pref.getDouble(speedKey);

    if (speed != null) {
      await _videoPlayerController.setPlaybackSpeed(speed);
    }
  }

  Future<void> _listenerSpeed() async {
    if (_videoPlayerController.value.isPlaying) {
      if (Platform.isIOS) {
        await _videoPlayerController.setPlaybackSpeed(
          _videoPlayerController.value.playbackSpeed,
        );
      }
    }
  }

  static const defaultHideControlsTimer = Duration(seconds: 5);

  final MediaControls? mediaControls;

  final MediaThumbnail? thumbnails;

  final MediaDescription? description;

  final MediaChromeCast? chromeCast;

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
  )? optionsBuilder;

  /// Add your own additional options on top of chewie options
  final List<OptionItem> Function(BuildContext context)? additionalOptions;

  /// Define here your own Widget on how your n'th subtitle will look like
  Widget Function(BuildContext context, dynamic subtitle)? subtitleBuilder;

  /// Add a List of Subtitles here in `Subtitles.subtitle`
  Subtitles? subtitle;

  /// The controller for the video you want to play
  late VideoPlayerController _videoPlayerController;

  VideoPlayerController get videoPlayerController => _videoPlayerController;

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

  final Directory? directory;

  /// Wether or not to show the controls when initializing the widget.
  final bool showControlsOnInitialize;

  /// Whether or not to show the controls at all
  final bool showControls;

  /// Controller to pass into the [InteractiveViewer] component
  final TransformationController? transformationController;

  /// Whether or not to allow zooming and panning
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

  final HttpServer? server;

  static ChewieController of(BuildContext context) {
    final chewieControllerProvider =
        context.dependOnInheritedWidgetOfExactType<ChewieControllerProvider>()!;

    return chewieControllerProvider.controller;
  }

  double? _aspectRatio;

  bool _isFullScreen = false;

  int _fitIndex = 0;

  HlsDownloaded? _hlsMaster;

  final _isInitialized = ValueNotifier(false);

  final List<BoxFit> _fitOptions = BoxFit.values;

  final _fit = ValueNotifier(BoxFit.contain);

  List<VideoTrack> _videoTracks = [];

  List<AudioTrack> _audioTracks = [];

  final defaultTrack = VideoTrack(isAuto: true, name: 'Auto');

  late VideoTrack _videoTrack = defaultTrack;

  AudioTrack? _audioTrack;

  ChromeCastController? _chromeCastController;

  AudioPlayerHandler? _audioHandler;

  AudioPlayerHandler? get audioHandler => _audioHandler;

  ValueNotifier<bool> get isInitialized => _isInitialized;

  List<VideoTrack> get videoTracks => _videoTracks;

  VideoTrack get videoTrack => _videoTrack;

  AudioTrack? get audioTrack => _audioTrack;

  List<AudioTrack> get audioTracks => _audioTracks;

  double? get aspectRatio => _aspectRatio;

  ValueNotifier<BoxFit> get fit => _fit;

  bool get isFullScreen => _isFullScreen;

  bool get isPlaying => _videoPlayerController.value.isPlaying;

  ChromeCastController? get chromeCastController => _chromeCastController;

  void startPip() {
    if (!isFullScreen) {
      enterFullScreen();
    }

    PiPManager.startPictureInPictureMode();
  }

  Future<void> setChromeCastController(ChromeCastController controller) async {
    _chromeCastController = controller;
    await _chromeCastController?.addSessionListener();
  }

  Future<void> onSessionStarted() async {
    await _chromeCastController?.loadMedia(
      await chromeCast!.onSessionStarted(),
      title: description?.title ?? '',
      subtitle: description?.subtitle ?? '',
    );
    await _videoPlayerController.pause();
  }

  static Future<void> initializeBg() async {
    // return JustAudioBackground.init(
    //   androidNotificationChannelId: 'uz.intersoft.chewie.channel.audio',
    //   androidNotificationChannelName: 'Audio playback',
    //   androidNotificationOngoing: true,
    // );
  }

  Future<void> setVideoTrack(VideoTrack track) async {
    if (directory != null && _hlsMaster != null) {
      final origin = await _hlsMaster!.origin.readAsString();
      _videoTrack = track;

      final changed = track.isAuto
          ? _audioTrack != null
              ? HlsParser(
                  playlistContent: origin,
                ).changeAudio(_audioTrack!)
              : origin
          : HlsParser(
              playlistContent: origin,
            ).changeResolution(track);

      await _hlsMaster?.master.writeAsString(
        changed,
      );

      if (!track.isAuto && track.audioGroupId != null) {
        if (_audioTrack?.groupId != null) {
          final audioTrackGroup = _audioTracks.where(
            (item) =>
                item.language == _audioTrack?.language &&
                item.groupId == track.audioGroupId,
          );

          final audioTrack = audioTrackGroup.firstOrNull;

          if (audioTrack != null) {
            await setAudioTrack(audioTrack);

            return;
          }
        }
      }

      await reloadDataSource();
    }
  }

  Future<void> setAudioTrack(AudioTrack track) async {
    if (directory != null && _hlsMaster != null) {
      final origin = _hlsMaster!.origin;
      _audioTrack = track;

      final changed = HlsParser(
        playlistContent: await origin.readAsString(),
      ).changeAudio(
        track,
        targetVideoTrack: _videoTrack.isAuto ? null : _videoTrack,
      );

      await _hlsMaster?.master.writeAsString(
        changed,
      );

      await reloadDataSource();
    }
  }

  Future<void> reloadDataSource() async {
    final prevPosition = _videoPlayerController.value.position;
    final speed = _videoPlayerController.value.playbackSpeed;
    _isInitialized.value = false;
    await _videoPlayerController.dispose();
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(_videoPlayerController.dataSource),
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: true,
        mixWithOthers: true,
      ),
    );

    await _videoPlayerController.initialize().then((_) async {
      unawaited(_initialize());
      _isInitialized.value = true;
      await _videoPlayerController.seekTo(prevPosition);
      await _videoPlayerController.setPlaybackSpeed(speed);
      await _videoPlayerController.play();
      _videoPlayerController.addListener(_listenerSpeed);
    });

    notifyListeners();
  }

  static Future<HttpServer> _startServerForFiles(
    Directory directory, {
    required int port,
  }) async {
    return shelf_io.serve(
      (request) => _serverHandlerForFiles(request, directory),
      'localhost',
      port,
    );
  }

  static Future<shelf.Response> _serverHandlerForFiles(
    shelf.Request request,
    Directory directory,
  ) async {
    final file = File('${directory.path}/${request.url.path}');

    if (file.existsSync()) {
      return shelf.Response.ok(await file.readAsString());
    }

    return shelf.Response.forbidden('File not found');
  }

  @override
  void dispose() {
    _videoPlayerController
      ..removeListener(_listenerSpeed)
      ..dispose();

    _audioHandler?.dispose();
    _audioHandler?.streamController.close();
    _audioHandler = null;
    server?.close();
    super.dispose();
  }

  Future<dynamic> _initialize() async {
    isInitialized.value = _videoPlayerController.value.isInitialized;

    unawaited(_initializeHlsDataFromNetwork());

    if (isInitialized.value) return;

    await _videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !_videoPlayerController.value.isInitialized) {
      await _videoPlayerController.initialize();
      _isInitialized.value = true;
      notifyListeners();
    }

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }

      await _videoPlayerController.play();
    }

    if (startAt != null) {
      await _videoPlayerController.seekTo(startAt!);
    }

    if (fullScreenByDefault) {
      _videoPlayerController.addListener(_fullScreenListener);
    }

    try {
      await initializeAudio();
      // ignore: empty_catches
    } catch (err) {}
  }

  Future<void> initializeAudio() async {
    _audioHandler = await AudioService.init(
      builder: AudioPlayerHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'uz.intersoft.chewie.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      ),
    );

    _audioHandler?.setMedia(
      MediaItem(
        id: videoPlayerController.dataSource,
        title: description?.title ?? 'Unknown',
        album: description?.album,
        artist: description?.artist,
        artUri: Uri.tryParse(description?.poster ?? ''),
        duration: _videoPlayerController.value.duration,
      ),
    );

    _audioHandler?.setVideoFunctions(_videoPlayerController.play,
        _videoPlayerController.pause, _videoPlayerController.seekTo, () {
      _videoPlayerController
        ..seekTo(Duration.zero)
        ..pause();
    });

    _audioHandler?.initializeStreamController(_videoPlayerController);

    await _audioHandler?.playbackState
        .addStream(_audioHandler!.streamController.stream);
  }

  Future<void> _initializeHlsDataFromNetwork() async {
    if (_hlsMaster != null && _videoTracks.isEmpty) {
      final parser = HlsParser(
        playlistContent: await _hlsMaster!.origin.readAsString(),
      );

      _videoTracks = [defaultTrack, ...parser.parseVideoTracks()];

      _audioTracks = parser.parseAudioTracks();

      notifyListeners();
    }
  }

  Future<void> _fullScreenListener() async {
    if (_videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      _videoPlayerController.removeListener(_fullScreenListener);
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

  void setAspectRatio(double value) {
    _aspectRatio = value;
    notifyListeners();
  }

  Future<void> play() async {
    await _videoPlayerController.play();
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> setLooping(bool looping) async {
    await _videoPlayerController.setLooping(looping);
  }

  Future<void> pause() async {
    await _videoPlayerController.pause();
  }

  Future<void> seekTo(Duration moment) async {
    await _videoPlayerController.seekTo(moment);
  }

  Future<void> setVolume(double volume) async {
    await _videoPlayerController.setVolume(volume);
  }

  void switchFit() {
    _fitIndex = (_fitIndex + 1) % _fitOptions.length;
    _fit.value = _fitOptions[_fitIndex];
  }

  void setSubtitle(List<Subtitle> newSubtitle) {
    subtitle = Subtitles(newSubtitle);
  }
}

class ChewieControllerProvider extends InheritedWidget {
  const ChewieControllerProvider({
    required this.controller,
    required super.child,
    super.key,
  });

  final ChewieController controller;

  @override
  bool updateShouldNotify(ChewieControllerProvider oldWidget) =>
      controller != oldWidget.controller;
}
