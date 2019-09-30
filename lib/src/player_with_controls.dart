import 'dart:ui';

import 'package:chewie_audio/src/chewie_player.dart';
import 'package:chewie_audio/src/cupertino_controls.dart';
import 'package:chewie_audio/src/material_controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  PlayerWithControls({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChewieAudioController chewieController =
        ChewieAudioController.of(context);

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: _buildPlayerWithControls(chewieController, context),
      ),
    );
  }

  Container _buildPlayerWithControls(
      ChewieAudioController chewieController, BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          Offstage(
            offstage: true,
            child: Container(
              width: 3,
              height: 1,
              child: VideoPlayer(chewieController.videoPlayerController),
            ),
          ),
          _buildControls(context, chewieController),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    ChewieAudioController chewieController,
  ) {
    return chewieController.showControls
        ? chewieController.customControls != null
            ? chewieController.customControls
            : Theme.of(context).platform == TargetPlatform.android
                ? MaterialControls()
                : CupertinoControls(
                    backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
                    iconColor: Color.fromARGB(255, 200, 200, 200),
                  )
        : Container();
  }
}
