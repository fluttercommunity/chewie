import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

String formatDuration(Duration position) {
  final ms = position.inMilliseconds;

  int seconds = ms ~/ 1000;
  final int hours = seconds ~/ 3600;
  seconds = seconds % 3600;
  final minutes = seconds ~/ 60;
  seconds = seconds % 60;

  final hoursString = hours >= 10
      ? '$hours'
      : hours == 0
          ? '00'
          : '0$hours';

  final minutesString = minutes >= 10
      ? '$minutes'
      : minutes == 0
          ? '00'
          : '0$minutes';

  final secondsString = seconds >= 10
      ? '$seconds'
      : seconds == 0
          ? '00'
          : '0$seconds';

  final formattedTime =
      '${hoursString == '00' ? '' : '$hoursString:'}$minutesString:$secondsString';

  return formattedTime;
}

bool getIsBuffering(VideoPlayerController controller) {
  final VideoPlayerValue value = controller.value;

  if (defaultTargetPlatform == TargetPlatform.android) {
    if (value.isBuffering) {
      // -> Check if we actually buffer, as android has a bug preventing to
      //    get the correct buffering state from this single bool.
      final int position = value.position.inMilliseconds;

      // Special case, if the video is finished, we don't want to show the
      // buffering indicator anymore
      if (position >= value.duration.inMilliseconds) {
        return false;
      } else {
        final int buffer = value.buffered.lastOrNull?.end.inMilliseconds ?? -1;

        return position >= buffer;
      }
    } else {
      // -> No buffering
      return false;
    }
  }

  return value.isBuffering;
}
