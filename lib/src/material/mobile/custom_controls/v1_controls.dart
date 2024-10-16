import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_cast_video/flutter_cast_video.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../chewie.dart';
import '../../../center_play_button.dart';
import '../../../config/colors.dart';
import '../../../config/icons.dart';
import '../../../helpers/extensions.dart';
import '../../../helpers/utils.dart';
import '../../../helpers/vtt_parser.dart';
import '../../../notifiers/index.dart';
import '../../../widgets/animations/player_animation.dart';
import '../../widgets/buttons/player_icon_button.dart';
import '../material_gesture.dart';
import '../material_settings/material_settings_main.dart';

// ignore: must_be_immutable
class V1Controls extends StatefulWidget {
  V1Controls({
    this.showPlayButton = true,
    super.key,
  }) {
    onHelpPressed = null;
  }

  final bool showPlayButton;

  VoidCallback? onHelpPressed;

  @override
  State<StatefulWidget> createState() {
    return _V1ControlsState();
  }
}

class _V1ControlsState extends State<V1Controls>
    with SingleTickerProviderStateMixin {
  late var _subtitlesPosition = Duration.zero;
  late VideoPlayerController controller;
  late VideoPlayerValue _latestValue;
  late PlayerNotifier notifier;

  Timer? _showAfterExpandCollapseTimer;
  Timer? _bufferingDisplayTimer;
  Timer? _hideTimer;
  Timer? _initTimer;

  bool _displayBufferingIndicator = false;
  bool _displayTapped = false;
  bool _subtitleOn = false;
  bool _dragging = false;

  final barHeight = 48.0 * 1.5;
  final marginSize = 5.0;

  ChewieController? _chewieController;
  ChewieController get chewieController => _chewieController!;

  List<WebVTTEntry>? _thumbnails;
  List<WebVTTEntry>? _thumbnailsPlaceholder;

  @override
  void initState() {
    super.initState();
    notifier = Provider.of<PlayerNotifier>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder?.call(
            context,
            chewieController.videoPlayerController.value.errorDescription!,
          ) ??
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 42,
                ),
                TextButton(
                  onPressed: () {
                    chewieController.reloadDataSource();
                  },
                  child: const Text('Reload'),
                ),
              ],
            ),
          );
    }

    return GestureDetector(
      onTap: () {
        if (notifier.hideStuff) {
          _cancelAndRestartTimer();
        } else {
          _showOrHide();
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: notifier.lockStuff,
              child: MaterialGesture(
                controller: chewieController,
                restartTimer: () {
                  if (!notifier.hideStuff) {
                    _cancelAndRestartTimer();
                  }
                },
              ),
            ),
          ),
          _buildPlayPause(),
          _buildActionBar(),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (_subtitleOn)
                Transform.translate(
                  offset: Offset(
                    0,
                    notifier.hideStuff ? barHeight * 0.8 : 0.0,
                  ),
                  child: _buildSubtitles(context, chewieController.subtitle!),
                ),
              _buildBottomBar(context),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dispose();

    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _chewieController;
    _chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildActionBar() {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: IgnorePointer(
                ignoring: notifier.lockStuff,
                child: Center(
                  child: PlayerAnimation(
                    alignment: Alignment.topCenter,
                    value: !(notifier.lockStuff || notifier.hideStuff),
                    duration: 250.ms,
                    child: Row(
                      children: [
                        PlayerIconButton(
                          onPressed: () {
                            if (chewieController.isFullScreen) {
                              chewieController.toggleFullScreen();
                            }
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          icon: PlayerIcons.close,
                        ),
                        const Spacer(),
                        if (widget.onHelpPressed != null)
                          PlayerIconButton(
                            onPressed: widget.onHelpPressed!,
                            icon: PlayerIconsCustom.v1.help,
                          ),
                        if (chewieController.chromeCast != null) ...[
                          const Gap(10),
                          ChromeCastButton(
                            size: 28,
                            color: Colors.white,
                            onRequestFailed: (err) {
                              notifier.showCastControls = false;
                            },
                            onSessionEnded: () {
                              notifier.showCastControls = false;
                              _chewieController?.play();
                            },
                            onButtonCreated:
                                chewieController.setChromeCastController,
                            onSessionStarted: () async {
                              await chewieController.onSessionStarted();
                              notifier.showCastControls = true;
                            },
                          ),
                          const Gap(10),
                        ],
                        if (kDebugMode) ...[
                          PlayerIconButton(
                            size: 38,
                            onPressed: () async {
                              notifier.hideStuff = true;

                              chewieController.startPip();
                            },
                            icon: PlayerIconsCustom.v1.pictureInPicture,
                          ),
                        ],
                        PlayerIconButton(
                          size: 36,
                          onPressed: () {
                            chewieController.switchFit();
                          },
                          icon: PlayerIcons.fullScreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitles(BuildContext context, Subtitles subtitles) {
    if (!_subtitleOn) {
      return const SizedBox();
    }
    final currentSubtitle = subtitles.getByPosition(_subtitlesPosition);
    if (currentSubtitle.isEmpty) {
      return const SizedBox();
    }

    if (chewieController.subtitleBuilder != null) {
      return chewieController.subtitleBuilder!(
        context,
        currentSubtitle.first!.text,
      );
    }

    return Padding(
      padding: EdgeInsets.all(marginSize),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0x96000000),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          currentSubtitle.first!.text.toString(),
          style: const TextStyle(
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
  ) {
    final mediaControls = chewieController.mediaControls;

    return IgnorePointer(
      ignoring: notifier.lockStuff,
      child: PlayerAnimation(
        value: !(notifier.lockStuff || notifier.hideStuff),
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: barHeight + (chewieController.isFullScreen ? 20.0 : 0),
          child: SafeArea(
            top: false,
            bottom: chewieController.isFullScreen,
            minimum: chewieController.controlsSafeAreaMinimum,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 12,
                      ),
                      child: _buildProgressBar(),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      PlayerIconButton(
                        onPressed: () {
                          showPlayerSettings(
                            context,
                            controller: chewieController,
                          );
                        },
                        icon: PlayerIconsCustom.v1.settings,
                      ),
                      if (mediaControls?.onOpen != null) ...[
                        PlayerIconButton(
                          onPressed: mediaControls!.onOpen!,
                          icon: PlayerIcons.stack,
                        ),
                      ],
                      const Gap(10),
                      _buildDuration(),
                      const Spacer(),
                      if (mediaControls?.onPrev != null) ...[
                        PlayerIconButton(
                          onPressed: mediaControls!.onPrev!,
                          icon: PlayerIconsCustom.v1.skipBackward,
                        ),
                      ],
                      if (mediaControls?.onNext != null) ...[
                        PlayerIconButton(
                          onPressed: mediaControls!.onNext!,
                          icon: PlayerIconsCustom.v1.skipForward,
                        ),
                      ],
                      if (chewieController.allowFullScreen)
                        _buildExpandButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return PlayerIconButton(
      onPressed: _onExpandCollapse,
      icon: chewieController.isFullScreen
          ? PlayerIcons.disableFullScreen
          : PlayerIconsCustom.v1.enterFullScreen,
    );
  }

  void _showOrHide() {
    if (_latestValue.isPlaying) {
      if (_displayTapped) {
        setState(() {
          notifier.hideStuff = true;
        });
      } else {
        _cancelAndRestartTimer();
      }
    } else {
      setState(() {
        notifier.hideStuff = true;
      });
    }
  }

  Widget _buildHitArea() {
    return GestureDetector(
      onTap: _showOrHide,
      child: Container(
        alignment: Alignment.center,
        color: Colors.transparent,
      ),
    );
  }

  Widget _buildPlayPause() {
    final isFinished = (_latestValue.position >= _latestValue.duration) &&
        _latestValue.duration.inSeconds > 0;
    final showPlayButton =
        widget.showPlayButton && !_dragging && !notifier.hideStuff;

    return IgnorePointer(
      ignoring: notifier.lockStuff,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isFinished && !chewieController.isLive)
            PlayerAnimation(
              value: !notifier.lockStuff && showPlayButton,
              alignment: Alignment.centerLeft,
              child: PlayerIconButton(
                size: 48,
                onPressed: _seekBackward,
                icon: PlayerIconsCustom.v1.backward10,
              ),
            ),
          SizedBox(
            width: 90,
            child: _displayBufferingIndicator
                ? _chewieController?.bufferingBuilder?.call(context) ??
                    const Center(
                      child: CupertinoActivityIndicator(
                        color: PlayerColors.white,
                        radius: 20,
                      ),
                    )
                : Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: marginSize,
                    ),
                    child: CenterPlayButton(
                      backgroundColor: Colors.transparent,
                      iconColor: Colors.white,
                      isFinished: isFinished,
                      isPlaying: controller.value.isPlaying,
                      show: !notifier.lockStuff && showPlayButton,
                      onPressed: _playPause,
                    ),
                  ),
          ),
          if (!isFinished && !chewieController.isLive)
            PlayerAnimation(
              value: !notifier.lockStuff && showPlayButton,
              alignment: Alignment.centerRight,
              child: PlayerIconButton(
                size: 48,
                onPressed: _seekForward,
                icon: PlayerIconsCustom.v1.forward10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPosition(Color? iconColor) {
    final position = _latestValue.position;

    return Text(
      formatDuration(position),
      style: context.s16.w600.copyWith(
        color: PlayerColors.white,
      ),
    );
  }

  Widget _buildDuration() {
    final duration = _latestValue.duration;

    return Text(
      formatDuration(duration),
      style: context.s16.w600.copyWith(
        color: PlayerColors.white,
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      notifier.hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<void> _initialize() async {
    _subtitleOn = chewieController.subtitle?.isNotEmpty ?? false;
    controller.addListener(_updateState);

    _updateState();

    if (controller.value.isPlaying || chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          notifier.hideStuff = false;
        });
      });
    }

    final thumbLarge = chewieController.thumbnails?.large;
    final thumbMedium = chewieController.thumbnails?.large;

    if (thumbLarge != null) {
      _thumbnails = WebVTTParser().parse(thumbLarge);
    }
    if (thumbMedium != null) {
      _thumbnailsPlaceholder = WebVTTParser().parse(thumbMedium);
    }
  }

  void _onExpandCollapse() {
    setState(() {
      notifier.hideStuff = true;

      chewieController.toggleFullScreen();
      _showAfterExpandCollapseTimer =
          Timer(const Duration(milliseconds: 300), () {
        setState(_cancelAndRestartTimer);
      });
    });
  }

  void _playPause() {
    final isFinished = (_latestValue.position >= _latestValue.duration) &&
        _latestValue.duration.inSeconds > 0;

    setState(() {
      if (controller.value.isPlaying) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration.zero);
          }
          controller.play();
        }
      }
    });
  }

  Future<void> _seekRelative(Duration relativeSeek) async {
    _cancelAndRestartTimer();
    final position = _latestValue.position + relativeSeek;
    final duration = _latestValue.duration;

    if (position < Duration.zero) {
      await controller.seekTo(Duration.zero);
    } else if (position > duration) {
      await controller.seekTo(duration);
    } else {
      await controller.seekTo(position);
    }
  }

  void _seekBackward() {
    _seekRelative(
      const Duration(
        seconds: -10,
      ),
    );
  }

  void _seekForward() {
    _seekRelative(
      const Duration(
        seconds: 10,
      ),
    );

    _cancelAndRestartTimer();
  }

  void _startHideTimer() {
    final hideControlsTimer = chewieController.hideControlsTimer.isNegative
        ? ChewieController.defaultHideControlsTimer
        : chewieController.hideControlsTimer;
    _hideTimer = Timer(hideControlsTimer, () {
      setState(() {
        notifier.hideStuff = true;
      });
    });
  }

  void _bufferingTimerTimeout() {
    _displayBufferingIndicator = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    if (!mounted) return;

    // display the progress bar indicator only after the buffering delay if it
    // has been set
    if (chewieController.progressIndicatorDelay != null) {
      if (controller.value.isBuffering) {
        _bufferingDisplayTimer ??= Timer(
          chewieController.progressIndicatorDelay!,
          _bufferingTimerTimeout,
        );
      } else {
        _bufferingDisplayTimer?.cancel();
        _bufferingDisplayTimer = null;
        _displayBufferingIndicator = false;
      }
    } else {
      _displayBufferingIndicator = controller.value.isBuffering;
    }

    setState(() {
      _latestValue = controller.value;
      _subtitlesPosition = controller.value.position;
    });
  }

  Widget _buildProgressBar() {
    return MaterialVideoProgressBar(
      controller,
      onDragStart: () {
        setState(() {
          _dragging = true;
        });

        _hideTimer?.cancel();
      },
      onDragUpdate: () {
        _hideTimer?.cancel();
      },
      onDragEnd: () {
        setState(() {
          _dragging = false;
        });

        _startHideTimer();
      },
      colors: ChewieProgressColors(
        playedColor: PlayerColorsCustom.v1.primary,
        handleColor: PlayerColorsCustom.v1.primary,
        backgroundColor: PlayerColors.white.withOpacity(0.8),
      ),
      thumbnails: _thumbnails,
      thumbnailsPlaceholder: _thumbnailsPlaceholder,
      draggableProgressBar: chewieController.draggableProgressBar,
    );
  }
}
