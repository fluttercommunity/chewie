import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'chewie_player.dart';
import 'config/colors.dart';
import 'helpers/adaptive_controls.dart';
import 'material/mobile/material_chrome_cast_controls.dart';
import 'notifiers/index.dart';

const speedKey = 'player:playback_speed';
bool isInBg = false;

class PlayerWithControls extends StatefulWidget {
  const PlayerWithControls({super.key});

  @override
  State<PlayerWithControls> createState() => _PlayerWithControlsState();
}

class _PlayerWithControlsState extends State<PlayerWithControls>
    with WidgetsBindingObserver {
  late ChewieController _chewieController = ChewieController.of(context);

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    log(state.name);
    log(isInBg.toString());

    if (!isInBg) {
      isInBg = state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden;
    }

    if (isInBg) {
      if (_chewieController.isPlaying) {
        await _chewieController.pause();
        await _chewieController.audioHandler?.startBgPlay(
          _chewieController.videoPlayerController.value.position,
          _chewieController.videoPlayerController.value.playbackSpeed,
        );
      }
    }

    if (state == AppLifecycleState.resumed && isInBg) {
      isInBg = false;
      final lastPosition = _chewieController.audioHandler?.stopBgPlay();
      log(lastPosition.toString());
      if (lastPosition == null) return;
      await _chewieController.videoPlayerController.seekTo(lastPosition);
      await _chewieController.play();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void didChangeDependencies() {
    _chewieController = ChewieController.of(context);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    double calculateAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      return width > height ? width / height : height / width;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: ClipRRect(
            child: Container(
              color: Colors.black,
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              child: AspectRatio(
                aspectRatio: calculateAspectRatio(context),
                child: Stack(
                  children: <Widget>[
                    if (_chewieController.placeholder != null)
                      _chewieController.placeholder!,
                    Center(
                      child: ListenableBuilder(
                        builder: (BuildContext context, Widget? child) {
                          return SizedBox.expand(
                            child: FittedBox(
                              fit: _chewieController.fit.value,
                              child: SizedBox(
                                width: _chewieController
                                    .videoPlayerController.value.size.width,
                                height: _chewieController
                                    .videoPlayerController.value.size.height,
                                child: _chewieController.isInitialized.value
                                    ? Consumer<PlayerNotifier>(
                                        builder: (
                                          BuildContext context,
                                          value,
                                          Widget? child,
                                        ) {
                                          if (value.showCastControls) {
                                            return const SizedBox();
                                          }

                                          return child!;
                                        },
                                        child: VideoPlayer(
                                          _chewieController
                                              .videoPlayerController,
                                        ),
                                      )
                                    : _chewieController.placeholder ??
                                        const SizedBox(),
                              ),
                            ),
                          );
                        },
                        listenable: Listenable.merge([
                          _chewieController.fit,
                          _chewieController.isInitialized,
                        ]),
                      ),
                    ),
                    if (_chewieController.overlay != null)
                      _chewieController.overlay!,
                    if (_chewieController.showControls)
                      Consumer<PlayerNotifier>(
                        builder: (
                          BuildContext context,
                          PlayerNotifier notifier,
                          Widget? widget,
                        ) =>
                            Visibility(
                          visible: !notifier.hideStuff,
                          child: AnimatedOpacity(
                            opacity: notifier.hideStuff ? 0.0 : 0.8,
                            duration: const Duration(
                              milliseconds: 250,
                            ),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(color: Colors.black54),
                              child: SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                    ValueListenableBuilder(
                      valueListenable: _chewieController.isInitialized,
                      builder: (context, value, child) {
                        if (!value) {
                          return const Center(
                            child: CupertinoActivityIndicator(
                              color: PlayerColors.white,
                              radius: 20,
                            ),
                          );
                        }

                        return _BuildControls(
                          controller: _chewieController,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BuildControls extends StatefulWidget {
  const _BuildControls({required this.controller});

  final ChewieController controller;

  @override
  State<_BuildControls> createState() => _BuildControlsState();
}

class _BuildControlsState extends State<_BuildControls> {
  late final _notifier = Provider.of<PlayerNotifier>(context, listen: false);

  bool _showCastControls = false;

  void _listener() {
    if (_notifier.showCastControls != _showCastControls) {
      setState(() {
        _showCastControls = _notifier.showCastControls;
      });
    }
  }

  @override
  void initState() {
    _notifier.addListener(_listener);
    super.initState();
  }

  @override
  void dispose() {
    _notifier.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showCastControls) {
      return const MaterialChromeCastControls();
    }

    if (!widget.controller.showControls) {
      return const SizedBox();
    }

    return widget.controller.customControls ?? const AdaptiveControls();
  }
}
