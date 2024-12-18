import 'dart:async';

import 'package:flutter_svg/svg.dart';
import 'package:chewie/src/center_play_button.dart';
import '../../src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:chewie/src/material/material_progress_bar.dart';
import 'package:chewie/src/material/widgets/options_dialog.dart';
import 'package:chewie/src/material/widgets/playback_speed_dialog.dart';
import 'package:chewie/src/models/option_item.dart';
import 'package:chewie/src/models/subtitle_model.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'widgets/product_live_player_timer.dart';

class GsshopLiveControls extends StatefulWidget {
  const GsshopLiveControls({
    this.showPlayButton = true,
    Key? key,
  }) : super(key: key);

  final bool showPlayButton;

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<GsshopLiveControls>
    with SingleTickerProviderStateMixin {
  late PlayerNotifier notifier;
  late VideoPlayerValue _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;
  late var _subtitlesPosition = Duration.zero;
  bool _subtitleOn = false;
  Timer? _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  Timer? _bufferingDisplayTimer;
  bool _displayBufferingIndicator = false;

  final barHeight = 48.0 * 1.5;
  final marginSize = 5.0;

  late VideoPlayerController controller;
  ChewieController? _chewieController;

  // We know that _chewieController is set in didChangeDependencies
  ChewieController get chewieController => _chewieController!;

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
          const Center(
            child: Icon(
              Icons.error,
              color: Colors.white,
              size: 42,
            ),
          );
    }

    return ValueListenableBuilder(
        valueListenable: chewieController.miniPlayerNotifier!,
        builder: (context, value, _) {
          return value
              ? Container()
              : MouseRegion(
                  onHover: (_) {
                    _cancelAndRestartTimer();
                  },
                  child: GestureDetector(
                    onTap: () => _cancelAndRestartTimer(),
                    child: AbsorbPointer(
                      absorbing: notifier.hideStuff,
                      child: Stack(
                        children: [
                          // if (_displayBufferingIndicator)
                          //   const Center(
                          //     child: CircularProgressIndicator(),
                          //   )
                          // else
                          _buildHitArea(),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              _buildBottomBar(context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
        });
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
      top: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedOpacity(
          opacity: notifier.hideStuff ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: Row(
            children: [
              _buildSubtitleToggle(),
              if (chewieController.showOptions) _buildOptionsButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsButton() {
    final options = <OptionItem>[
      OptionItem(
        onTap: () async {
          Navigator.pop(context);
          _onSpeedButtonTap();
        },
        iconData: Icons.speed,
        title: chewieController.optionsTranslation?.playbackSpeedButtonText ??
            'Playback speed',
      )
    ];

    if (chewieController.additionalOptions != null &&
        chewieController.additionalOptions!(context).isNotEmpty) {
      options.addAll(chewieController.additionalOptions!(context));
    }

    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: IconButton(
        onPressed: () async {
          _hideTimer?.cancel();

          if (chewieController.optionsBuilder != null) {
            await chewieController.optionsBuilder!(context, options);
          } else {
            await showModalBottomSheet<OptionItem>(
              context: context,
              isScrollControlled: true,
              useRootNavigator: chewieController.useRootNavigator,
              builder: (context) => OptionsDialog(
                options: options,
                cancelButtonText:
                    chewieController.optionsTranslation?.cancelButtonText,
              ),
            );
          }

          if (_latestValue.isPlaying) {
            _startHideTimer();
          }
        },
        icon: const Icon(
          Icons.more_vert,
          color: Colors.white,
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
          borderRadius: BorderRadius.circular(10.0),
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

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    final iconColor = Theme.of(context).textTheme.labelLarge!.color;

    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: SafeArea(
        bottom: chewieController.isFullScreen,
        minimum: chewieController.controlsSafeAreaMinimum,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (chewieController.leftTime == null ||
                      chewieController.leftTime == '') ...[
                    const SizedBox(
                      width: 12,
                    ),
                    _buildPosition(iconColor),
                  ],
                  const Spacer(),
                  // if (chewieController.isLive)
                  //   const Expanded(child: Text('LIVE'))
                  // else
                  //   _buildPosition(iconColor),
                  if (chewieController.allowMuting)
                    _buildMuteButton(controller),

                  if (chewieController.allowFullScreen) _buildExpandButton(),
                  Container(
                    width: 12.0,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: chewieController.isFullScreen ? 20.0 : 10.0,
            ),
            // if (!chewieController.isLive)
            //   Expanded(
            //     child: Container(
            //       padding: const EdgeInsets.only(right: 20),
            //       child: Row(
            //         children: [
            //           _buildProgressBar(),
            //         ],
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();
        print('live button _latestValue.volume ${_latestValue.volume}');
        if (_latestValue.volume == 0) {
          _latestVolume == 1.0;
          controller.setVolume(1.0);
          chewieController.volumeOnFunction();
        } else {
          _latestVolume = controller.value.volume;
          chewieController.volumeOffFunction();

          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: 36,
          width: 36,
          color: const Color.fromARGB(0, 255, 255, 255),
          child: Center(
            child: _latestValue.volume > 0.0
                ? SvgPicture.asset(
                    'assets/svg/icon/player/volume_up.svg',
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    width: 20,
                    height: 20,
                  )
                : SvgPicture.asset(
                    'assets/svg/icon/player/volume_down.svg',
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    width: 20,
                    height: 20,
                  ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 36.0,
          height: 36.0,
          color: const Color.fromARGB(0, 255, 255, 255),
          child: Center(
            child: chewieController.isFullScreen
                ? SvgPicture.asset(
                    'assets/svg/icon/player/zoom_out.svg',
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    width: 20,
                    height: 20,
                  )
                : SvgPicture.asset(
                    'assets/svg/icon/player/zoom_in.svg',
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    width: 20,
                    height: 20,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    final bool isFinished = _latestValue.position >= _latestValue.duration;
    final bool showPlayButton =
        widget.showPlayButton && !_dragging && !notifier.hideStuff;

    return GestureDetector(
      onTap: () {
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
      },
      child: AnimatedOpacity(
        opacity: showPlayButton ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black.withAlpha(38),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 48.0,
              ),
              CenterPlayButton(
                backgroundColor: const Color(0xff191923).withOpacity(0.38),
                iconColor: Colors.white,
                isFinished: false,
                isPlaying: controller.value.isPlaying,
                show: showPlayButton,
                onPressed: _playPause,
              ),
              const SizedBox(
                height: 8.0,
              ),
              if (chewieController.leftTime != null)
                ProductLivePlayerTimer(
                  leftTime: chewieController.leftTime!,
                  show: showPlayButton,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSpeedButtonTap() async {
    _hideTimer?.cancel();

    final chosenSpeed = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: chewieController.useRootNavigator,
      builder: (context) => PlaybackSpeedDialog(
        speeds: chewieController.playbackSpeeds,
        selected: _latestValue.playbackSpeed,
      ),
    );

    if (chosenSpeed != null) {
      controller.setPlaybackSpeed(chosenSpeed);
    }

    if (_latestValue.isPlaying) {
      _startHideTimer();
    }
  }

  Widget _buildPosition(Color? iconColor) {
    final position = _latestValue.position;
    final duration = _latestValue.duration;

    return RichText(
      text: TextSpan(
        text: '${formatDuration(position)} ',
        children: <InlineSpan>[
          TextSpan(
            text: '/ ${formatDuration(duration)}',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.white.withOpacity(.75),
              fontWeight: FontWeight.normal,
            ),
          )
        ],
        style: const TextStyle(
          fontSize: 14.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubtitleToggle() {
    //if don't have subtitle hiden button
    if (chewieController.subtitle?.isEmpty ?? true) {
      return const SizedBox();
    }
    return GestureDetector(
      onTap: _onSubtitleTap,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: Icon(
          _subtitleOn
              ? Icons.closed_caption
              : Icons.closed_caption_off_outlined,
          color: _subtitleOn ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  void _onSubtitleTap() {
    setState(() {
      _subtitleOn = !_subtitleOn;
    });
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
  }

  void _onExpandCollapse() {
    setState(() {
      notifier.hideStuff = true;
      var isChange = chewieController.toggleFullScreenFunction();
      if (isChange) {
        chewieController.toggleFullScreen();

        _showAfterExpandCollapseTimer =
            Timer(const Duration(milliseconds: 300), () {
          setState(() {
            _cancelAndRestartTimer();
          });
        });
      }
    });
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
        chewieController.pauseFunction();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
            chewieController.playFunction();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration.zero);
          }
          chewieController.playFunction();
          controller.play();
        }
      }
    });
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

    // display the progress bar indicator only after the buffering delay if it has been set
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
    return Expanded(
      child: MaterialVideoProgressBar(
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
        colors: chewieController.materialProgressColors ??
            ChewieProgressColors(
              playedColor: Theme.of(context).colorScheme.secondary,
              handleColor: Theme.of(context).colorScheme.secondary,
              bufferedColor:
                  Theme.of(context).colorScheme.background.withOpacity(0.5),
              backgroundColor: Theme.of(context).disabledColor.withOpacity(.5),
            ),
      ),
    );
  }
}
