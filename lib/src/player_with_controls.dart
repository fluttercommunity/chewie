import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/helpers/adaptive_controls.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);

    double _calculateAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      return width > height ? width / height : height / width;
    }

    Widget _buildControls(
      BuildContext context,
      ChewieController chewieController,
    ) {
      return chewieController.showControls
          ? chewieController.customControls ?? const AdaptiveControls()
          : Container();
    }

    Widget _buildPlayerWithControls(
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
              child: AspectRatio(
                aspectRatio: chewieController.aspectRatio ??
                    chewieController.videoPlayerController.value.aspectRatio,
                child: CroppedVideo(
                  controller: chewieController.videoPlayerController,
                  cropAspectRatio: chewieController.aspectRatio!,
                ),
              ),
            ),
          ),
          if (chewieController.overlay != null) chewieController.overlay!,
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
          if (!chewieController.isFullScreen)
            _buildControls(context, chewieController)
          else
            SafeArea(
              bottom: false,
              child: _buildControls(context, chewieController),
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
          child: _buildPlayerWithControls(chewieController, context),
        ),
      ),
    );
  }
}

class CroppedVideo extends StatefulWidget {
  CroppedVideo({required this.controller, required this.cropAspectRatio});

  final VideoPlayerController controller;
  final double cropAspectRatio;

  @override
  CroppedVideoState createState() => CroppedVideoState();
}

class CroppedVideoState extends State<CroppedVideo> {
  VideoPlayerController get controller => widget.controller;

  double get cropAspectRatio => widget.cropAspectRatio;
  bool initialized = false;

  late VoidCallback listener;

  @override
  void initState() {
    super.initState();
    _waitForInitialized();
  }

  @override
  void didUpdateWidget(CroppedVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(listener);
      initialized = false;
      _waitForInitialized();
    }
  }

  void _waitForInitialized() {
    listener = () {
      if (!mounted) {
        return;
      }
      if (initialized != controller.value.isInitialized) {
        initialized = controller.value.isInitialized;
        setState(() {});
      }
    };
    controller.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (initialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: cropAspectRatio ?? controller.value.aspectRatio,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size?.width ?? 0,
              height: controller.value.size?.height ?? 0,
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
