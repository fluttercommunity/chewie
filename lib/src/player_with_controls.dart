import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'chewie_player.dart';
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
              child: ValueListenableBuilder(
                builder: (BuildContext context, value, Widget? child) {
                  return SizedBox.expand(
                    child: FittedBox(
                      fit: value,
                      child: SizedBox(
                        width: chewieController
                            .videoPlayerController.value.size.width,
                        height: chewieController
                            .videoPlayerController.value.size.height,
                        child: child,
                      ),
                    ),
                  );
                },
                valueListenable: chewieController.fit,
                child: VideoPlayer(chewieController.videoPlayerController),
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
          if (!chewieController.isFullScreen)
            buildControls(context, chewieController)
          else
            SafeArea(
              bottom: false,
              child: buildControls(context, chewieController),
            ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: Container(
            color: Colors.black,
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: AspectRatio(
              aspectRatio: calculateAspectRatio(context),
              child: buildPlayerWithControls(chewieController, context),
            ),
          ),
        );
      },
    );
  }
}
