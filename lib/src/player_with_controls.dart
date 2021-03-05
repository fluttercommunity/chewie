import 'dart:ui';

import 'package:chewie_audio/src/chewie_player.dart';
import 'package:chewie_audio/src/cupertino_controls.dart';
import 'package:chewie_audio/src/material_controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChewieAudioController chewieController = ChewieAudioController.of(context);

    Widget _buildControls(
      BuildContext context,
      ChewieAudioController chewieController,
    ) {
      final controls = Theme.of(context).platform == TargetPlatform.android
          ? const MaterialControls()
          : const CupertinoControls(
              backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
              iconColor: Color.fromARGB(255, 200, 200, 200),
            );
      return chewieController.showControls
          ? chewieController.customControls ?? controls
          : Container();
    }

    Stack _buildPlayerWithControls(
        ChewieAudioController chewieController, BuildContext context) {
      return Stack(
        children: <Widget>[
          Offstage(
            child: SizedBox(
              width: 3,
              height: 1,
              child: VideoPlayer(chewieController.videoPlayerController),
            ),
          ),
          _buildControls(context, chewieController),
        ],
      );
    }

    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: _buildPlayerWithControls(chewieController, context),
      ),
    );
  }
}
