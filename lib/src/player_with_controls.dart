import 'package:chewie/src/cast/widgets/cast_overlay.dart';
import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/helpers/adaptive_controls.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/material.dart';
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
          ? chewieController.customControls ?? const AdaptiveControls()
          : const SizedBox();
    }

    Widget buildPlayerWithControls(
      ChewieController chewieController,
      BuildContext context,
    ) {
      final playerNotifier = context.read<PlayerNotifier>();
      final child = Stack(
        children: [
          if (chewieController.placeholder != null)
            chewieController.placeholder!,
          _VideoSurface(chewieController: chewieController),
          if (chewieController.overlay != null) chewieController.overlay!,
          if (Theme.of(context).platform != TargetPlatform.iOS)
            Consumer<PlayerNotifier>(
              builder:
                  (
                    BuildContext context,
                    PlayerNotifier notifier,
                    Widget? widget,
                  ) => Visibility(
                    visible: !notifier.hideStuff,
                    child: AnimatedOpacity(
                      opacity: notifier.hideStuff ? 0.0 : 0.8,
                      duration: const Duration(milliseconds: 250),
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

      if (chewieController.zoomAndPan ||
          chewieController.transformationController != null) {
        return InteractiveViewer(
          transformationController: chewieController.transformationController,
          maxScale: chewieController.maxScale,
          panEnabled: chewieController.zoomAndPan,
          scaleEnabled: chewieController.zoomAndPan,
          onInteractionUpdate: chewieController.zoomAndPan
              ? (_) => playerNotifier.hideStuff = true
              : null,
          onInteractionEnd: chewieController.zoomAndPan
              ? (_) => playerNotifier.hideStuff = false
              : null,
          child: child,
        );
      }

      return child;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: SizedBox(
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

/// The picture itself: the local video texture, or the casting overlay while a
/// session has the video.
///
/// Split out and rebuilt off the cast controller because [ChewieController]
/// deliberately does not notify on cast changes — notifying there means
/// "fullscreen changed" and would pop the fullscreen route.
class _VideoSurface extends StatelessWidget {
  const _VideoSurface({required this.chewieController});

  final ChewieController chewieController;

  @override
  Widget build(BuildContext context) {
    final castController = chewieController.castController;

    if (castController == null) {
      return _buildLocal();
    }

    return AnimatedBuilder(
      animation: castController,
      builder: (context, _) {
        // Only swap once playback has actually moved to the receiver. While a
        // session is merely being set up the local player is still the one
        // playing, and covering it up would hide a picture that is still
        // running — the pulsing cast button is the feedback for that phase.
        if (!chewieController.isCasting) {
          return _buildLocal();
        }

        final device = chewieController.castDevice;
        return chewieController.castOverlayBuilder?.call(context, device) ??
            CastOverlay(
              device: device,
              translations: chewieController.castTranslations,
            );
      },
    );
  }

  Widget _buildLocal() {
    return Center(
      child: AspectRatio(
        aspectRatio:
            chewieController.aspectRatio ??
            chewieController.videoPlayerController.value.aspectRatio,
        child: VideoPlayer(chewieController.videoPlayerController),
      ),
    );
  }
}
