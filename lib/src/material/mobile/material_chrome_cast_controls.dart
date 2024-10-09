import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_cast_video/flutter_cast_video.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../chewie.dart';
import '../../config/icons.dart';
import '../../helpers/extensions.dart';
import '../../notifiers/index.dart';
import '../../progress_bar.dart';
import '../../widgets/svg/svg_asset.dart';
import '../widgets/buttons/player_icon_button.dart';

class MaterialChromeCastControls extends StatefulWidget {
  const MaterialChromeCastControls({super.key});

  @override
  State<MaterialChromeCastControls> createState() =>
      _MaterialChromeCastControlsState();
}

class _MaterialChromeCastControlsState
    extends State<MaterialChromeCastControls> {
  late ChewieController _chewieController = ChewieController.of(context);
  late final _castController = _chewieController.chromeCastController;
  late PlayerNotifier _notifier = Provider.of<PlayerNotifier>(
    context,
    listen: false,
  );

  ChewieController get chewieController => _chewieController;

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    _chewieController = ChewieController.of(context);
    _notifier = Provider.of<PlayerNotifier>(context, listen: false);

    _chewieController
      ..pause()
      ..removeListener(_listener)
      ..addListener(_listener);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: chewieController.isFullScreen,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SvgAsset(
                  PlayerIcons.chromeCast,
                  width: 100,
                  height: 100,
                  color: Colors.white38,
                ),
                Text(
                  'Chrome cast',
                  style: context.s16.w600.copyWith(
                    color: Colors.white38,
                  ),
                ),
                const Gap(24),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PlayerIconButton(
                      onPressed: () async {
                        await _castController?.stop();
                        await _chewieController.play();
                        _notifier
                          ..showCastControls = false
                          ..hideStuff = true;
                      },
                      icon: PlayerIcons.close,
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 20,
                      child: ChromeCastButton(
                        size: 20,
                        color: Colors.white,
                        onRequestFailed: print,
                        onPlayerStatusUpdated: print,
                        onSessionEnded: () {
                          _notifier.showCastControls = false;
                        },
                        onButtonCreated:
                            _chewieController.setChromeCastController,
                        onSessionStarted: () async {
                          await _chewieController.onSessionStarted();
                        },
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_castController != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 10,
                            child: _VideoProgressBar(
                              _castController,
                              barHeight: 5,
                              handleHeight: 10,
                              drawShadow: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Gap(6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PlayerIconButton(
                      onPressed: () {
                        _castController?.seek(
                          relative: true,
                          interval: -10,
                        );
                      },
                      icon: PlayerIcons.backward10,
                    ),
                    if (_castController != null)
                      _CastPlayPauseButton(_castController),
                    PlayerIconButton(
                      onPressed: () {
                        _castController?.seek(
                          relative: true,
                        );
                      },
                      icon: PlayerIcons.forward10,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CastPlayPauseButton extends StatefulWidget {
  const _CastPlayPauseButton(this.controller);
  final ChromeCastController controller;

  @override
  State<_CastPlayPauseButton> createState() => __CastPlayPauseButtonState();
}

class __CastPlayPauseButtonState extends State<_CastPlayPauseButton> {
  Timer? _listenerTimer;

  bool _isPlaying = false;

  Future<void> _listener() async {
    if (!mounted) return;
    final isPlaying = await widget.controller.isPlaying();
    if (_isPlaying != isPlaying) {
      setState(() {});
      _isPlaying = isPlaying ?? false;
    }
  }

  @override
  void initState() {
    super.initState();

    _listenerTimer = Timer.periodic(1.seconds, (_) => _listener());
  }

  @override
  void dispose() {
    super.dispose();
    _listenerTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return PlayerIconButton(
      onPressed: () {
        if (_isPlaying) {
          widget.controller.pause();
        } else {
          widget.controller.play();
        }

        _isPlaying = !_isPlaying;

        setState(() {});
      },
      icon: _isPlaying ? PlayerIcons.pause : PlayerIcons.play,
    );
  }
}

class _VideoProgressBar extends StatefulWidget {
  _VideoProgressBar(
    this.controller, {
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
    ChewieProgressColors? colors,
  }) : colors = colors ?? ChewieProgressColors();

  final ChromeCastController controller;
  final ChewieProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  _VideoProgressBarState createState() {
    return _VideoProgressBarState();
  }
}

class _VideoProgressBarState extends State<_VideoProgressBar> {
  Future<void> _listener() async {
    if (!mounted) return;
    setState(() {});

    if (_latestDraggableOffset == null) {
      position = await widget.controller.position();
    }

    duration = await widget.controller.duration();
  }

  Offset? _latestDraggableOffset;

  Timer? _listenerTimer;

  Duration? duration;
  Duration? position;

  @override
  void initState() {
    super.initState();

    _listenerTimer = Timer.periodic(1.seconds, (_) => _listener());
  }

  @override
  void dispose() {
    super.dispose();
    _listenerTimer?.cancel();
  }

  Future<void> _seekToRelativePosition(Offset globalPosition) async {
    await widget.controller
        .seek(
      interval: context
          .calcRelativePosition(
            await widget.controller.duration(),
            globalPosition,
          )
          .inSeconds
          .toDouble(),
    )
        .then(
      (_) {
        _latestDraggableOffset = null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: StaticProgressBar(
        colors: widget.colors,
        value: VideoPlayerValue(
          duration: duration ?? const Duration(seconds: 5),
          position: position ?? Duration.zero,
          isInitialized: true,
        ),
        barHeight: widget.barHeight,
        drawShadow: widget.drawShadow,
        handleHeight: widget.handleHeight,
        latestDraggableOffset: _latestDraggableOffset,
      ),
    );

    return GestureDetector(
      onTapDown: (details) {},
      onTapCancel: () {},
      onHorizontalDragUpdate: (DragUpdateDetails details) async {
        _latestDraggableOffset = details.globalPosition;
        unawaited(_listener());
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_latestDraggableOffset != null) {
          _seekToRelativePosition(details.globalPosition);
        }
      },
      onTapUp: (TapUpDetails details) async {
        _latestDraggableOffset = details.globalPosition;
        await _seekToRelativePosition(details.globalPosition);
      },
      child: child,
    );
  }
}
