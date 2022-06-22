import 'dart:async';

import 'package:chewieLumen/src/center_buttons.dart';
import 'package:chewieLumen/src/chewie_player.dart';
import 'package:chewieLumen/src/chewie_progress_colors.dart';
import 'package:chewieLumen/src/helpers/utils.dart';
import 'package:chewieLumen/src/material/material_progress_bar.dart';
import 'package:chewieLumen/src/material/widgets/options_dialog.dart';
import 'package:chewieLumen/src/material/widgets/playback_speed_dialog.dart';
import 'package:chewieLumen/src/models/option_item.dart';
import 'package:chewieLumen/src/models/subtitle_model.dart';
import 'package:chewieLumen/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class MaterialControls extends StatefulWidget {
  const MaterialControls({
    this.showPlayButton = true,
    this.showPrevNextButtons = false,
    this.showVideoInfo = false,
    this.videoTitle,
    this.videoSubtitle,
    this.playIconColor = Colors.black,
    this.backgroundPlayIconColor = Colors.white,
    this.prevNextIconsColor = Colors.white,
    this.isPrevButtonDisabled = true,
    this.isNextButtonDisabled = true,
    this.positionTextSize = 14.0,
    this.muteButtonSize = 14.0,
    this.videoHeightOverflowValue,
    this.onPrevClicked,
    this.onNextClicked,
    Key? progressBarKey,
    Key? key,
  })  : _progressBarKey = progressBarKey,
        super(key: key);

  final bool showPlayButton;
  final bool showPrevNextButtons;
  final bool showVideoInfo;
  final Widget? videoTitle;
  final Widget? videoSubtitle;
  final Color backgroundPlayIconColor;
  final Color prevNextIconsColor;
  final Color playIconColor;
  final bool isPrevButtonDisabled;
  final bool isNextButtonDisabled;
  final double positionTextSize;
  final double muteButtonSize;
  final double? videoHeightOverflowValue;
  final Key? _progressBarKey;
  final void Function()? onPrevClicked;
  final void Function()? onNextClicked;

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls> with SingleTickerProviderStateMixin {
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

  final barHeight = 48.0 * 1.5;
  final marginSize = 5.0;

  late VideoPlayerController controller;
  ChewieLumenController? _chewieLumenController;

  // We know that _chewieLumenController is set in didChangeDependencies
  ChewieLumenController get chewieLumenController => _chewieLumenController!;

  @override
  void initState() {
    super.initState();
    notifier = Provider.of<PlayerNotifier>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieLumenController.errorBuilder?.call(
            context,
            chewieLumenController.videoPlayerController.value.errorDescription!,
          ) ??
          const Center(
            child: Icon(
              Icons.error,
              color: Colors.white,
              size: 42,
            ),
          );
    }

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: notifier.hideStuff,
          child: Stack(
            children: [
              if (_latestValue.isBuffering)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                _buildHitArea(),
              _buildActionBar(),
              if (widget.showVideoInfo) _buildVideoInfo(widget.videoHeightOverflowValue),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (_subtitleOn)
                    Transform.translate(
                      offset: Offset(
                        0.0,
                        notifier.hideStuff ? barHeight * 0.8 : 0.0,
                      ),
                      child: _buildSubtitles(context, chewieLumenController.subtitle!),
                    ),
                  _buildBottomBar(context, widget._progressBarKey, widget.videoHeightOverflowValue),
                ],
              ),
            ],
          ),
        ),
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
    final _oldController = _chewieLumenController;
    _chewieLumenController = ChewieLumenController.of(context);
    controller = chewieLumenController.videoPlayerController;

    if (_oldController != chewieLumenController) {
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
              if (chewieLumenController.showOptions) _buildOptionsButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo([double? videoHeightOverflowValue]) {
    const topPosition = 30.0;
    return Positioned(
      top: videoHeightOverflowValue != null ? videoHeightOverflowValue + topPosition : topPosition,
      left: 20,
      child: SafeArea(
        child: AnimatedOpacity(
          opacity: notifier.hideStuff ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.videoTitle != null)
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: widget.videoTitle,
                ),
              if (widget.videoSubtitle != null) ...[
                const SizedBox(height: 5.0),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: widget.videoSubtitle,
                )
              ],
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
        title: chewieLumenController.optionsTranslation?.playbackSpeedButtonText ?? 'Playback speed',
      )
    ];

    if (chewieLumenController.additionalOptions != null &&
        chewieLumenController.additionalOptions!(context).isNotEmpty) {
      options.addAll(chewieLumenController.additionalOptions!(context));
    }

    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: IconButton(
        onPressed: () async {
          _hideTimer?.cancel();

          if (chewieLumenController.optionsBuilder != null) {
            await chewieLumenController.optionsBuilder!(context, options);
          } else {
            await showModalBottomSheet<OptionItem>(
              context: context,
              isScrollControlled: true,
              useRootNavigator: chewieLumenController.useRootNavigator,
              builder: (context) => OptionsDialog(
                options: options,
                cancelButtonText: chewieLumenController.optionsTranslation?.cancelButtonText,
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
      return Container();
    }
    final currentSubtitle = subtitles.getByPosition(_subtitlesPosition);
    if (currentSubtitle.isEmpty) {
      return Container();
    }

    if (chewieLumenController.subtitleBuilder != null) {
      return chewieLumenController.subtitleBuilder!(
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
    Key? key,
    double? videoHeightOverflowValue,
  ) {
    final bottomPadding = videoHeightOverflowValue ?? 0;
    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: barHeight + (chewieLumenController.isFullScreen ? 10.0 + bottomPadding : 0 + bottomPadding),
        padding: EdgeInsets.only(
          left: 20,
          bottom: !chewieLumenController.isFullScreen ? 10.0 + bottomPadding : 0 + bottomPadding,
        ),
        child: SafeArea(
          bottom: chewieLumenController.isFullScreen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    if (chewieLumenController.isLive)
                      const Expanded(child: Text('LIVE'))
                    else
                      _buildPosition(widget.positionTextSize),
                    if (chewieLumenController.allowMuting) _buildMuteButton(controller, widget.muteButtonSize),
                    const Spacer(),
                    if (chewieLumenController.allowFullScreen) _buildExpandButton(),
                  ],
                ),
              ),
              SizedBox(
                height: chewieLumenController.isFullScreen ? 15.0 : 0,
              ),
              if (!chewieLumenController.isLive)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      children: [
                        _buildProgressBar(key),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(VideoPlayerController controller, double muteButtonSize) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.only(
              left: 6.0,
            ),
            child: Icon(
              _latestValue.volume > 0 ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
              size: muteButtonSize,
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
          height: barHeight + (chewieLumenController.isFullScreen ? 15.0 : 0),
          margin: const EdgeInsets.only(right: 12.0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              chewieLumenController.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    final bool isFinished = _latestValue.position >= _latestValue.duration;
    final bool showPlayButton = widget.showPlayButton && !_dragging && !notifier.hideStuff;

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
          _playPause();

          setState(() {
            notifier.hideStuff = true;
          });
        }
      },
      child: CenterButtons(
        backgroundPlayIconColor: widget.backgroundPlayIconColor,
        playIconColor: widget.playIconColor,
        prevNextIconsColor: widget.prevNextIconsColor,
        isFinished: isFinished,
        isPlaying: controller.value.isPlaying,
        show: showPlayButton,
        withMaterialPrevAndNextButtons: widget.showPrevNextButtons,
        isPrevButtonDisabled: widget.isPrevButtonDisabled,
        isNextButtonDisabled: widget.isNextButtonDisabled,
        onPlayPressed: _playPause,
        onPrevClicked: widget.onPrevClicked,
        onNextClicked: widget.onNextClicked,
      ),
    );
  }

  Future<void> _onSpeedButtonTap() async {
    _hideTimer?.cancel();

    final chosenSpeed = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: chewieLumenController.useRootNavigator,
      builder: (context) => PlaybackSpeedDialog(
        speeds: chewieLumenController.playbackSpeeds,
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

  Widget _buildPosition(double positionTextSize) {
    final position = _latestValue.position;
    final duration = _latestValue.duration;

    return RichText(
      text: TextSpan(
        text: '${formatDuration(position)} ',
        children: <InlineSpan>[
          TextSpan(
            text: '/ ${formatDuration(duration)}',
            style: TextStyle(
              fontSize: positionTextSize,
              color: Colors.white.withOpacity(.75),
              fontWeight: FontWeight.normal,
            ),
          )
        ],
        style: TextStyle(
          fontSize: positionTextSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubtitleToggle() {
    //if don't have subtitle hiden button
    if (chewieLumenController.subtitle?.isEmpty ?? true) {
      return Container();
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
          _subtitleOn ? Icons.closed_caption : Icons.closed_caption_off_outlined,
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
    _subtitleOn = chewieLumenController.subtitle?.isNotEmpty ?? false;
    controller.addListener(_updateState);

    _updateState();

    if (controller.value.isPlaying || chewieLumenController.autoPlay) {
      _startHideTimer();
    }

    if (chewieLumenController.showControlsOnInitialize) {
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

      chewieLumenController.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
        _chewieLumenController?.onPlayPaused?.call(true);
      } else {
        _cancelAndRestartTimer();
        _chewieLumenController?.onPlayPaused?.call(false);

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

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        notifier.hideStuff = true;
      });
    });
  }

  void _updateState() {
    if (!mounted) return;
    setState(() {
      _latestValue = controller.value;
      _subtitlesPosition = controller.value.position;
    });
  }

  Widget _buildProgressBar(
    Key? key,
  ) {
    return Expanded(
      child: MaterialVideoProgressBar(
        controller,
        key: key,
        onDragStart: () {
          setState(() {
            _dragging = true;
          });

          _hideTimer?.cancel();
        },
        onDragEnd: () {
          setState(() {
            _dragging = false;
          });
          _startHideTimer();
        },
        onProgressChanged: chewieLumenController.onProgressChanged?.call,
        colors: chewieLumenController.materialProgressColors ??
            ChewieLumenProgressColors(
              playedColor: Theme.of(context).colorScheme.secondary,
              handleColor: Theme.of(context).colorScheme.secondary,
              bufferedColor: Theme.of(context).backgroundColor.withOpacity(0.5),
              backgroundColor: Theme.of(context).disabledColor.withOpacity(.5),
            ),
      ),
    );
  }
}
