import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'chewie_player.dart';
import 'config/colors.dart';
import 'helpers/adaptive_controls.dart';
import 'notifiers/index.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({super.key});

  @override
  Widget build(BuildContext context) {
    final chewieController = ChewieController.of(context);

    double calculateAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      return width > height ? width / height : height / width;
    }

    Widget buildControls(
      BuildContext context,
      ChewieController chewieController,
    ) {
      return chewieController.showControls
          ? chewieController.customControls ?? const AdaptiveControls()
          : const SizedBox();
    }

    Widget buildPlayerWithControls(
      ChewieController chewieController,
      BuildContext context,
    ) {
      return Stack(
        children: <Widget>[
          if (chewieController.placeholder != null)
            chewieController.placeholder!,
          InteractiveViewer(
            transformationController: chewieController.transformationController,
            maxScale: chewieController.maxScale,
            panEnabled: chewieController.zoomAndPan,
            scaleEnabled: chewieController.zoomAndPan,
            child: Center(
              child: ListenableBuilder(
                builder: (BuildContext context, Widget? child) {
                  return SizedBox.expand(
                    child: FittedBox(
                      fit: chewieController.fit.value,
                      child: SizedBox(
                        width: chewieController
                            .videoPlayerController.value.size.width,
                        height: chewieController
                            .videoPlayerController.value.size.height,
                        child: chewieController.isInitialized.value
                            ? VideoPlayer(
                                chewieController.videoPlayerController,
                              )
                            : chewieController.placeholder ?? const SizedBox(),
                      ),
                    ),
                  );
                },
                listenable: Listenable.merge([
                  chewieController.fit,
                  chewieController.isInitialized,
                ]),
              ),
            ),
          ),
          if (chewieController.overlay != null) chewieController.overlay!,
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
            valueListenable: chewieController.isInitialized,
            builder: (context, value, child) {
              if (!value) {
                return const Center(
                  child: CupertinoActivityIndicator(
                    color: PlayerColors.white,
                    radius: 20,
                  ),
                );
              }

              if (!chewieController.isFullScreen) {
                return buildControls(context, chewieController);
              } else {
                return SafeArea(
                  bottom: false,
                  child: buildControls(context, chewieController),
                );
              }
            },
          ),
        ],
      );
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
                child: buildPlayerWithControls(chewieController, context),
              ),
            ),
          ),
        );
      },
    );
  }
}
