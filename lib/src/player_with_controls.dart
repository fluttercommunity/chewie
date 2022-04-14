import 'package:chewieLumen/src/chewie_player.dart';
import 'package:chewieLumen/src/helpers/adaptive_controls.dart';
import 'package:chewieLumen/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChewieLumenController chewieLumenController = ChewieLumenController.of(context);

    double _calculateAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      return width > height ? width / height : height / width;
    }

    Widget _buildControls(
      BuildContext context,
      ChewieLumenController chewieLumenController,
    ) {
      return chewieLumenController.showControls
          ? chewieLumenController.customControls ?? const AdaptiveControls()
          : Container();
    }

    Widget _buildPlayerWithControls(
      ChewieLumenController chewieLumenController,
      BuildContext context,
    ) {
      return Stack(
        children: <Widget>[
          if (chewieLumenController.placeholder != null)
            chewieLumenController.placeholder!,
          InteractiveViewer(
            maxScale: chewieLumenController.maxScale,
            panEnabled: chewieLumenController.zoomAndPan,
            scaleEnabled: chewieLumenController.zoomAndPan,
            child: Center(
              child: AspectRatio(
                aspectRatio: chewieLumenController.aspectRatio ??
                    chewieLumenController.videoPlayerController.value.aspectRatio,
                child: VideoPlayer(chewieLumenController.videoPlayerController),
              ),
            ),
          ),
          if (chewieLumenController.overlay != null) chewieLumenController.overlay!,
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
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black54),
                    child: Container(),
                  ),
                ),
              ),
            ),
          if (!chewieLumenController.isFullScreen)
            _buildControls(context, chewieLumenController)
          else
            SafeArea(
              bottom: false,
              child: _buildControls(context, chewieLumenController),
            ),
        ],
      );
    }

    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio: _calculateAspectRatio(context),
          child: _buildPlayerWithControls(chewieLumenController, context),
        ),
      ),
    );
  }
}
