import 'package:flutter/material.dart';
import 'package:in_app_picture_in_picture/src/chewie_player.dart';
import 'package:in_app_picture_in_picture/src/helpers/adaptive_controls.dart';
import 'package:in_app_picture_in_picture/src/notifiers/index.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({super.key});

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);

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
          ? chewieController.customControls ??
              AdaptiveControls(
                onClose: chewieController.onCloseCallback,
              )
          : Container();
    }

    Widget buildPlayerWithControls(ChewieController chewieController, BuildContext context) {
      return Stack(
        children: <Widget>[
          chewieController.placeholder ?? Container(),
          Center(
            child: AspectRatio(
              aspectRatio: chewieController.aspectRatio ??
                  chewieController.videoPlayerController.value.aspectRatio,
              child: VideoPlayer(chewieController.videoPlayerController),
            ),
          ),
          chewieController.overlay ?? Container(),
          if (Theme.of(context).platform != TargetPlatform.iOS)
            Consumer<PlayerNotifier>(
              builder: (
                BuildContext context,
                PlayerNotifier notifier,
                Widget? widget,
              ) =>
                  AnimatedOpacity(
                opacity: notifier.hideStuff ? 0.0 : 0.8,
                duration: const Duration(
                  milliseconds: 250,
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.black54),
                  child: Container(),
                ),
              ),
            ),
          if (!chewieController.isFullScreen)
            buildControls(context, chewieController)
          else
            SafeArea(
              bottom: false,
              top: false,
              child: buildControls(context, chewieController),
            ),
        ],
      );
    }

    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio: calculateAspectRatio(context),
          child: buildPlayerWithControls(chewieController, context),
        ),
      ),
    );
  }
}
