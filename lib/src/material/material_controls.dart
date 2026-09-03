import 'dart:async';

import 'package:chewie/src/cast/chewie_cast_controller.dart';
import 'package:chewie/src/cast/chewie_playback_target.dart';
import 'package:chewie/src/cast/widgets/cast_button.dart';
import 'package:chewie/src/center_play_button.dart';
import 'package:chewie/src/center_seek_button.dart';
import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:chewie/src/material/material_progress_bar.dart';
import 'package:chewie/src/material/widgets/options_dialog.dart';
import 'package:chewie/src/material/widgets/playback_speed_dialog.dart';
import 'package:chewie/src/models/chewie_control_style.dart';
import 'package:chewie/src/models/option_item.dart';
import 'package:chewie/src/models/subtitle_model.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:chewie/src/subtitle_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class MaterialControls extends StatefulWidget {
  const MaterialControls({this.showPlayButton = true, super.key});

  final bool showPlayButton;

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls>
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

  /// Whether to draw the buffering spinner.
  ///
  /// Not while playback is remote — a cast session, or AirPlay and anything
  /// else reported through `externalPlayback`. The phone is a remote control
  /// rather than a video surface then, whatever is showing the video reports
  /// its own loading state on the screen the viewer is actually watching, and
  /// a spinner over the overlay is noise on top of a picture nobody is
  /// looking at.
  bool get _showBufferingIndicator =>
      _displayBufferingIndicator && !chewieController.isPlaybackRemote;

  final barHeight = 48.0 * 1.5;
  final marginSize = 5.0;

  late VideoPlayerController controller;
  ChewieController? _chewieController;

  /// The cast controller we are subscribed to, remembered separately so we
  /// unsubscribe from the same object we subscribed to even when the
  /// [ChewieController] is swapped out from under us.
  ChewieCastController? _subscribedCast;

  /// The external-playback signal we are subscribed to, remembered for the
  /// same reason as [_subscribedCast].
  ValueListenable<bool>? _subscribedExternalPlayback;

  ChewieCastController? get _castController =>
      _chewieController?.castController;

  /// Local player or cast receiver, whichever currently has the video.
  ChewiePlaybackTarget get _playback => chewieController.playback;

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
          const Center(child: Icon(Icons.error, color: Colors.white, size: 42));
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
              if (_showBufferingIndicator)
                _chewieController?.bufferingBuilder?.call(context) ??
                    const Center(child: CircularProgressIndicator())
              else
                _buildHitArea(),
              _buildActionBar(),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (_subtitleOn)
                    Transform.translate(
                      offset: Offset(
                        0.0,
                        notifier.hideStuff ? barHeight * 0.8 : 0.0,
                      ),
                      child: _buildSubtitles(
                        context,
                        chewieController.subtitle!,
                      ),
                    ),
                  _buildBottomBar(context),
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
    _subscribedCast?.removeListener(_updateState);
    _subscribedCast = null;
    _subscribedExternalPlayback?.removeListener(_updateState);
    _subscribedExternalPlayback = null;
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
              if (chewieController.additionalControls != null)
                ChewieControlStyle(
                  iconSize: 24,
                  iconColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                  decorate: (child) => child,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: chewieController.additionalControls!(context),
                  ),
                ),
              if (_castController != null && chewieController.allowCasting)
                CastButton(
                  castController: _castController!,
                  translations: chewieController.castTranslations,
                  useRootNavigator: chewieController.useRootNavigator,
                  cancelButtonText:
                      chewieController.optionsTranslation?.cancelButtonText,
                  onMenuOpened: () => _hideTimer?.cancel(),
                  onMenuClosed: () {
                    if (_latestValue.isPlaying) _startHideTimer();
                  },
                ),
              _buildSubtitleToggle(),
              if (chewieController.showOptions) _buildOptionsButton(),
            ],
          ),
        ),
      ),
    );
  }

  List<OptionItem> _buildOptions(BuildContext context) {
    final options = <OptionItem>[
      OptionItem(
        onTap: (context) async {
          Navigator.pop(context);
          _onSpeedButtonTap();
        },
        iconData: Icons.speed,
        title:
            chewieController.optionsTranslation?.playbackSpeedButtonText ??
            'Playback speed',
      ),
    ];

    if (chewieController.additionalOptions != null &&
        chewieController.additionalOptions!(context).isNotEmpty) {
      options.addAll(chewieController.additionalOptions!(context));
    }
    return options;
  }

  Widget _buildOptionsButton() {
    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: IconButton(
        onPressed: () async {
          _hideTimer?.cancel();

          if (chewieController.optionsBuilder != null) {
            await chewieController.optionsBuilder!(
              context,
              _buildOptions(context),
            );
          } else {
            await showModalBottomSheet<OptionItem>(
              context: context,
              isScrollControlled: true,
              useRootNavigator: chewieController.useRootNavigator,
              builder: (context) => OptionsDialog(
                options: _buildOptions(context),
                cancelButtonText:
                    chewieController.optionsTranslation?.cancelButtonText,
              ),
            );
          }

          if (_latestValue.isPlaying) {
            _startHideTimer();
          }
        },
        icon: const Icon(Icons.more_vert, color: Colors.white),
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

    return SubtitleOverlay(
      chewieController: chewieController,
      margin: EdgeInsets.all(marginSize),
      text: currentSubtitle.first!.text,
    );
  }

  AnimatedOpacity _buildBottomBar(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.labelLarge!.color;

    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: barHeight + (chewieController.isFullScreen ? 10.0 : 0),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: !chewieController.isFullScreen ? 10.0 : 0,
        ),
        child: SafeArea(
          top: false,
          bottom: chewieController.isFullScreen,
          minimum: chewieController.controlsSafeAreaMinimum,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    if (chewieController.isLive)
                      const Expanded(child: Text('LIVE'))
                    else
                      _buildPosition(iconColor),
                    if (chewieController.allowMuting)
                      _buildMuteButton(controller),
                    const Spacer(),
                    if (chewieController.allowFullScreen) _buildExpandButton(),
                  ],
                ),
              ),
              SizedBox(height: chewieController.isFullScreen ? 15.0 : 0),
              if (!chewieController.isLive)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [_buildProgressBar()]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(VideoPlayerController controller) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();
        final playback = _playback;

        if (_latestValue.volume == 0) {
          playback.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = playback.value.volume;
          playback.setVolume(0.0);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedOpacity(
          opacity: notifier.hideStuff ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: ClipRect(
            child: Container(
              height: barHeight,
              padding: const EdgeInsets.only(left: 6.0),
              child: Icon(
                _latestValue.volume > 0 ? Icons.volume_up : Icons.volume_off,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedOpacity(
          opacity: notifier.hideStuff ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            height: barHeight + (chewieController.isFullScreen ? 15.0 : 0),
            margin: const EdgeInsets.only(right: 12.0),
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Center(
              child: Icon(
                chewieController.isFullScreen
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    // Nothing to sit on while playback is remote: the video surface is the
    // casting or AirPlay overlay by then, and these buttons would cover it -
    // invisibly still taking its taps if they were merely faded out. The
    // control bar keeps play/pause and the progress bar for driving whatever
    // is playing.
    if (chewieController.isPlaybackRemote) return const SizedBox.expand();

    final bool isFinished =
        (_latestValue.position >= _latestValue.duration) &&
        _latestValue.duration.inSeconds > 0;
    final bool showPlayButton =
        widget.showPlayButton && !_dragging && !notifier.hideStuff;

    return GestureDetector(
      onTap: () {
        if (_latestValue.isPlaying) {
          if (_chewieController?.pauseOnBackgroundTap ?? false) {
            _playPause();
            _cancelAndRestartTimer();
          } else {
            if (_displayTapped) {
              setState(() {
                notifier.hideStuff = true;
              });
            } else {
              _cancelAndRestartTimer();
            }
          }
        } else {
          _playPause();

          setState(() {
            notifier.hideStuff = true;
          });
        }
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors
            .transparent, // The Gesture Detector doesn't expand to the full size of the container without this; Not sure why!
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isFinished && !chewieController.isLive)
              CenterSeekButton(
                iconData: Icons.replay_10,
                backgroundColor: Colors.black54,
                iconColor: Colors.white,
                show: showPlayButton,
                fadeDuration: chewieController.materialSeekButtonFadeDuration,
                iconSize: chewieController.materialSeekButtonSize,
                onPressed: _seekBackward,
              ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: marginSize),
              child: CenterPlayButton(
                backgroundColor: Colors.black54,
                iconColor: Colors.white,
                isFinished: isFinished,
                isPlaying: _latestValue.isPlaying,
                show: showPlayButton,
                onPressed: _playPause,
              ),
            ),
            if (!isFinished && !chewieController.isLive)
              CenterSeekButton(
                iconData: Icons.forward_10,
                backgroundColor: Colors.black54,
                iconColor: Colors.white,
                show: showPlayButton,
                fadeDuration: chewieController.materialSeekButtonFadeDuration,
                iconSize: chewieController.materialSeekButtonSize,
                onPressed: _seekForward,
              ),
          ],
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
      _playback.setPlaybackSpeed(chosenSpeed);
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
              color: Colors.white.withValues(alpha: .75),
              fontWeight: FontWeight.normal,
            ),
          ),
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: barHeight,
          color: Colors.transparent,
          padding: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: Icon(
            _subtitleOn
                ? Icons.closed_caption
                : Icons.closed_caption_off_outlined,
            color: _subtitleOn ? Colors.white : Colors.grey[700],
          ),
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
    _subtitleOn =
        chewieController.showSubtitles &&
        (chewieController.subtitle?.isNotEmpty ?? false);
    controller.addListener(_updateState);
    // Follow the receiver too: while casting it, not the local player, is what
    // reports position and play state.
    _subscribedCast = chewieController.castController
      ?..addListener(_updateState);
    // And whatever else took the video off this device, so the controls stop
    // drawing over a surface the viewer is not watching.
    _subscribedExternalPlayback = chewieController.externalPlayback
      ?..addListener(_updateState);

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

      chewieController.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(
        const Duration(milliseconds: 300),
        () {
          setState(() {
            _cancelAndRestartTimer();
          });
        },
      );
    });
  }

  void _playPause() {
    final bool isFinished =
        (_latestValue.position >= _latestValue.duration) &&
        _latestValue.duration.inSeconds > 0;

    final playback = _playback;

    setState(() {
      if (playback.value.isPlaying) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        playback.pause();
      } else {
        _cancelAndRestartTimer();

        // Only the local player has an uninitialized state to recover from —
        // a receiver is either loaded or there is no session.
        if (!playback.isRemote && !controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            playback.seekTo(Duration.zero);
          }
          playback.play();
        }
      }
    });
  }

  void _seekRelative(Duration relativeSeek) {
    _cancelAndRestartTimer();
    final playback = _playback;
    final position = _latestValue.position + relativeSeek;
    final duration = _latestValue.duration;

    if (position < Duration.zero) {
      playback.seekTo(Duration.zero);
    } else if (position > duration) {
      playback.seekTo(duration);
    } else {
      playback.seekTo(position);
    }
  }

  void _seekBackward() {
    _seekRelative(const Duration(seconds: -10));
  }

  void _seekForward() {
    _seekRelative(const Duration(seconds: 10));
  }

  void _startHideTimer() {
    // While casting the phone is a remote control, not a video surface: there
    // is nothing behind the controls worth revealing, and hiding them costs the
    // user a tap, because the first one only brings them back.
    if (chewieController.isPlaybackRemote) return;
    final hideControlsTimer = chewieController.hideControlsTimer.isNegative
        ? ChewieController.defaultHideControlsTimer
        : chewieController.hideControlsTimer;
    _hideTimer = Timer(hideControlsTimer, () {
      if (!mounted) return;
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

  /// Shows the controls without marking widgets dirty in the middle of a build.
  ///
  /// [_updateState] runs from `didChangeDependencies` as well as from player
  /// notifications, and the [PlayerNotifier] lives above this widget: setting
  /// it during a build marks an ancestor dirty, which the framework rejects.
  /// Reachable whenever a cast session is already live when this widget is
  /// built, which happens because senders outlive the screens that make them.
  void _revealControls() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) notifier.hideStuff = false;
      });
      return;
    }

    notifier.hideStuff = false;
  }

  void _updateState() {
    if (!mounted) return;

    final playback = _playback;
    // A session starting must not leave the controls hidden behind an
    // AbsorbPointer that swallows the next tap.
    if (playback.isRemote && notifier.hideStuff) {
      _revealControls();
    }

    // The Android buffering workaround in getIsBuffering only applies to the
    // local plugin; a receiver reports its own state honestly.
    final bool buffering = playback.isRemote
        ? playback.value.isBuffering
        : getIsBuffering(controller);

    // display the progress bar indicator only after the buffering delay if it has been set
    if (chewieController.progressIndicatorDelay != null) {
      if (buffering) {
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
      _displayBufferingIndicator = buffering;
    }

    setState(() {
      _latestValue = playback.value;
      _subtitlesPosition = playback.value.position;
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
        playback: _playback,
        colors:
            chewieController.materialProgressColors ??
            ChewieProgressColors(
              playedColor: Theme.of(context).colorScheme.secondary,
              handleColor: Theme.of(context).colorScheme.secondary,
              bufferedColor: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.5),
              backgroundColor: Theme.of(
                context,
              ).disabledColor.withValues(alpha: .5),
            ),
        draggableProgressBar: chewieController.draggableProgressBar,
      ),
    );
  }
}
