import 'dart:io';

import 'package:video_player/video_player.dart';

extension VideoPlayerControllerExtension on VideoPlayerController {
  VideoPlayerController copyWithAsset({
    String? dataSource,
    String? package,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
  }) {
    return VideoPlayerController.asset(
      dataSource ?? this.dataSource,
      package: package ?? this.package,
      closedCaptionFile: closedCaptionFile ?? this.closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions ?? this.videoPlayerOptions,
    );
  }

  VideoPlayerController copyWithFile({
    File? file,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
  }) {
    return VideoPlayerController.file(
      file ?? File.fromUri(Uri.parse(dataSource)),
      closedCaptionFile: closedCaptionFile ?? this.closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions ?? this.videoPlayerOptions,
    );
  }

  VideoPlayerController copyWithNetwork({
    String? dataSource,
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String>? httpHeaders,
  }) {
    return VideoPlayerController.network(
      dataSource ?? this.dataSource,
      formatHint: formatHint ?? this.formatHint,
      closedCaptionFile: closedCaptionFile ?? this.closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions ?? this.videoPlayerOptions,
      httpHeaders: httpHeaders ?? this.httpHeaders,
    );
  }
}
