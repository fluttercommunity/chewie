String formatDuration(Duration position) {
  final ms = position.inMilliseconds;

  var seconds = ms ~/ 1000;
  final hours = seconds ~/ 3600;
  seconds = seconds % 3600;
  final minutes = seconds ~/ 60;
  seconds = seconds % 60;

  // Ensure the strings are always two digits
  final hoursString = hours.toString().padLeft(2, '0');
  final minutesString = minutes.toString().padLeft(2, '0');
  final secondsString = seconds.toString().padLeft(2, '0');

  final formattedTime = '$hoursString:$minutesString:$secondsString';

  if (hours == 0) {
    return '$minutesString:$secondsString';
  }

  return formattedTime;
}
