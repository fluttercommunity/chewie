import 'package:chewie/chewie.dart';
import 'package:chewie_example/app/app.dart';
import 'package:flutter/material.dart';
// ignore_for_file: depend_on_referenced_packages
import 'package:video_player/video_player.dart';

void main() {
  runApp(
    const ChewieVideoPlayer(),
  );
}

class ChewieVideoPlayer extends StatefulWidget {
  const ChewieVideoPlayer({Key? key}) : super(key: key);

  @override
  State<ChewieVideoPlayer> createState() => _ChewieVideoPlayerState();
}

class _ChewieVideoPlayerState extends State<ChewieVideoPlayer> {
  TargetPlatform? _platform;
  late VideoPlayerController videoPlayerController;
  ChewieController? chewieController;

  @override
  void initState() {
    super.initState();
    initializeVideoPlayer();
  }

  Future<void> initializeVideoPlayer() async {
    videoPlayerController = VideoPlayerController.network(
      "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
    );

    await videoPlayerController.initialize();

    chewieController = ChewieController(
      materialProgressColors: ChewieProgressColors(playedColor: Colors.blue),
      videoPlayerController: videoPlayerController,
      autoInitialize: true,
      autoPlay: true,
      looping: true,
      errorBuilder: (context, errorMessage) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chewie = chewieController;
    return MaterialApp(
      theme: Theme.of(context).copyWith(
        platform: _platform ?? Theme.of(context).platform,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("ChewiePlayer"),
        ),
        body: Center(
          child:
              chewie != null && chewie.videoPlayerController.value.isInitialized
                  ? Chewie(
                      controller: chewie,
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    ),
        ),
      ),
    );
  }
}
