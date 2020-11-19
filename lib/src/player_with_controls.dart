import 'package:chewie_audio/src/chewie_player.dart';
import 'package:chewie_audio/src/helpers/adaptive_controls.dart';
import 'package:chewie_audio/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChewieAudioController chewieController =
        ChewieAudioController.of(context);

    Widget buildControls(
      BuildContext context,
      ChewieAudioController chewieController,
    ) {
      return chewieController.showControls
          ? chewieController.customControls ?? const AdaptiveControls()
          : const SizedBox();
    }

    Widget buildPlayerWithControls(
      ChewieAudioController chewieController,
      BuildContext context,
    ) {
      return Stack(
        children: <Widget>[
          InteractiveViewer(
            transformationController: chewieController.transformationController,
            maxScale: chewieController.maxScale,
            panEnabled: chewieController.zoomAndPan,
            scaleEnabled: chewieController.zoomAndPan,
            child: Center(
              child: VideoPlayer(chewieController.videoPlayerController),
            ),
          ),
          if (Theme.of(context).platform != TargetPlatform.iOS)
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
          SafeArea(
            bottom: false,
            child: buildControls(context, chewieController),
          ),
        ],
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: buildPlayerWithControls(chewieController, context),
    );
  }
}
