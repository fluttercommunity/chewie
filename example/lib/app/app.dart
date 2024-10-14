import 'dart:developer';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:chewie_example/app/theme.dart';
import 'package:chewie_example/app/thumbnail_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:system_files_viewer/system_files_viewer.dart';

class ChewieDemo extends StatefulWidget {
  const ChewieDemo({
    super.key,
    this.title = 'Chewie Demo',
  });

  final String title;

  @override
  State<StatefulWidget> createState() {
    return _ChewieDemoState();
  }
}

Future<SecurityContext> getSecurityContext() async {
  final certData = await rootBundle.load('assets/cer/cert.pem');
  final keyData = await rootBundle.load('assets/cer/key.pem');

  // Get the temporary directory where we can save the files
  final tempDir = await getTemporaryDirectory();

  // Write the certificate and key to temporary files
  final certFile = File('${tempDir.path}/cert.pem');
  final keyFile = File('${tempDir.path}/key.pem');

  if (!(await certFile.exists())) {
    await certFile.writeAsBytes(certData.buffer.asUint8List());
  }

  if (!(await keyFile.exists())) {
    await keyFile.writeAsBytes(keyData.buffer.asUint8List());
  }

  return SecurityContext()
    ..useCertificateChain(certFile.path)
    ..usePrivateKey(keyFile.path);
}

class _ChewieDemoState extends State<ChewieDemo> {
  TargetPlatform? _platform;
  ChewieController? _chewieController;
  int? bufferDelay;
  File? masterFile;
  Dio dio = Dio(
    BaseOptions(
      headers: {'content-type': 'application/json'},
    ),
  );

  @override
  void initState() {
    super.initState();
    // initializePlayer();

    // _prepareHlsFile();

    Future.sync(() async {
      try {
        _chewieController = await ChewieController.fromHlsUrl(
            url: src,
            autoPlay: true,
            mediaControls: MediaControls(
              onNext: () {},
              onOpen: () {},
              onPrev: () {},
            ),
            chromeCast: MediaChromeCast(
              onSessionStarted: () {
                return 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
              },
            ),
            customControls: ChewieCustomControls.v1Controls,
            zoomAndPan: true,
            description: const MediaDescription(
              title: 'Тень и кость (сериал 2021)',
            ),
            thumbnails: const MediaThumbnail(
              medium: thumbnailTest,
              large: thumbnailTest,
            ),
            deviceOrientationsAfterFullScreen: [
              DeviceOrientation.portraitUp,
            ]);
      } catch (err) {}
      setState(() {});
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    super.dispose();
  }

  String src =
      "https://vod03.splay.uz/hls10/Debris%202021%20S01E11/_tmp_/master.m3u8";

  Future<String> parseM3U8(String master) async {
    final resolutionPattern = RegExp(r'RESOLUTION=(\d+x\d+)');
    // final bandwidthPattern = RegExp(r'BANDWIDTH=(\d+)');
    // final codecPattern = RegExp(r'CODECS="([^"]+)"');
    final urlPattern = RegExp(r'(url_\d+\/[^\s]+\.m3u8)');

    // final directory = await getTemporaryDirectory();
    // Replace all relative URLs with the full absolute URL
    // final updatedPlaylist = master.replaceAllMapped(urlPattern, (match) {
    //   final relativeUrl = match.group(1);
    //   return '${directory.path}/$relativeUrl';
    // });

    final resolutions = resolutionPattern.allMatches(master);
    // final bandwidths = bandwidthPattern.allMatches(master);
    // final codecs = codecPattern.allMatches(master);
    final urls = urlPattern.allMatches(master);

    // Iterate through matches and print out resolution, bandwidth, codecs, and URL
    for (var i = 0; i < resolutions.length; i++) {
      // final resolution = resolutions.elementAt(i).group(1);
      // final bandwidth = bandwidths.elementAt(i).group(1);
      // final codec = codecs.elementAt(i).group(1);
      final streamUrl = urls.elementAt(i).group(1);

      // print(
      //     'Resolution: $resolution, Bandwidth: $bandwidth, Codecs: $codec, URL: $streamUrl');

      // preparePlaylist(streamUrl!);
    }

    return master;
  }

  Future<void> preparePlaylist(String url) async {
    final directory = await getTemporaryDirectory();
    await dio.download(
      'https://test-streams.mux.dev/x36xhzz/$url',
      '${directory.path}/$url',
    );

    final streamFile = File('${directory.path}/$url');

    final urlPattern = RegExp(r'(url_\d+/[^\s]+\.ts)');

    final playlist = await streamFile.readAsString();

    final paths = url.split('/');

    // Replace all relative URLs with the full absolute URL
    final updatedPlaylist = playlist.replaceAllMapped(urlPattern, (match) {
      final relativeUrl = match.group(1);
      return 'https://test-streams.mux.dev/x36xhzz/${paths.first}/$relativeUrl';
    });

    streamFile.writeAsString(updatedPlaylist);
  }

  String filterHLSPlaylist(String playlistContent, String resolution) {
    List<String> lines = playlistContent.split('\n');

    List<String> filteredLines = [];

    bool hasRes = false;

    for (String line in lines) {
      if (line.contains('#EXT-X-STREAM-INF') &&
          line.contains('NAME="$resolution"')) {
        hasRes = true;
      } else if (line.contains('#EXT-X-STREAM-INF')) {
        hasRes = false;
      }

      // If this is the 240p stream or any non-stream metadata, keep the lines
      if (hasRes || line.startsWith('#')) {
        filteredLines.add(line);
      }
    }

    // Join the filtered lines back into a single string and return the result
    return filteredLines.join('\n');
  }

  Future<void> initializePlayer() async {
    // final directory = await getTemporaryDirectory();
    await _startServer();
    setState(() {});
  }

  Future<void> _openFilesPage() async {
    final directory = await getTemporaryDirectory();

    SystemFilesViewer.openDirectoryPage(
      context: context,
      directory: directory,
    );

    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) {
    //       return SelectionArea(
    //         child: FileDetailsPage(
    //           file: masterFile!,
    //         ),
    //       );
    //     },
    //   ),
    // );
  }

  Future<void> _startServer() async {
    final handler = const shelf.Pipeline().addHandler((request) async {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${request.url.path}');

      return shelf.Response.ok(file.openRead());
    });

    final server = await shelf_io.serve(
      handler,
      'localhost',
      8080,
    );

    print('Server running on localhost:${server.port}');
  }

  Future<void> _prepareHlsFile() async {
    final baseDir = await getTemporaryDirectory();

    final path = '${baseDir.path}/master.m3u8';
    // final path240p = '${baseDir.path}/master240.m3u8';
    // final path720p = '${baseDir.path}/master720.m3u8';

    await dio.download(
      'https://vod02.splay.uz/hls8/Saboq%2055-qism%20%28Serial%20Rizanova%29/_tmp_/master.m3u8',
      path,
    );

    masterFile = File(path);

    final parsed = await masterFile!.readAsString();

    masterFile = await masterFile?.writeAsString(parsed);

    // File(path240p).writeAsString(filterHLSPlaylist(parsed, '240'));
    // File(path720p).writeAsString(filterHLSPlaylist(parsed, '720'));

    setState(() {});

    initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return _chewieController == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : MaterialApp(
            title: widget.title,
            theme: AppTheme.light.copyWith(
              platform: _platform ?? Theme.of(context).platform,
            ),
            home: Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Center(
                          child: Chewie(
                        controller: _chewieController!,
                      )),
                    ),
                    TextButton(
                      onPressed: () {
                        _chewieController?.enterFullScreen();
                      },
                      child: const Text('Fullscreen'),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text("Landscape Video"),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              // setState(() {
                              // _chewieController = _chewieController!.copyWith(
                              //   videoPlayerController:
                              //       _videoPlayerController1,
                              //   autoPlay: true,
                              //   looping: true,
                              /* subtitle: Subtitles([
                              Subtitle(
                                index: 0,
                                start: Duration.zero,
                                end: const Duration(seconds: 10),
                                text: 'Hello from subtitles',
                              ),
                              Subtitle(
                                index: 0,
                                start: const Duration(seconds: 10),
                                end: const Duration(seconds: 20),
                                text: 'Whats up? :)',
                              ),
                            ]),
                            subtitleBuilder: (context, subtitle) => Container(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                subtitle,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ), */
                              // );
                              // });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text("Portrait Video"),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              _openFilesPage();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text("Open files"),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              if (_chewieController?.mediaControls?.onNext ==
                                  null) {
                                _chewieController = _chewieController?.copyWith(
                                  mediaControls: MediaControls(
                                    onNext: () {
                                      log('on next');
                                    },
                                    onOpen: () {
                                      log('on open');
                                    },
                                    onPrev: () {
                                      log('on prev');
                                    },
                                  ),
                                );
                              } else {
                                _chewieController = _chewieController?.copyWith(
                                  mediaControls: MediaControls(
                                    onNext: null,
                                    onOpen: null,
                                    onPrev: null,
                                  ),
                                );
                              }

                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text("Media controls"),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _platform = TargetPlatform.android;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text("Android controls"),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _platform = TargetPlatform.iOS;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text("iOS controls"),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _platform = TargetPlatform.windows;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text("Desktop controls"),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (Platform.isAndroid)
                      ListTile(
                        title: const Text("Delay"),
                        subtitle: DelaySlider(
                          delay: _chewieController
                              ?.progressIndicatorDelay?.inMilliseconds,
                          onSave: (delay) async {
                            if (delay != null) {
                              bufferDelay = delay == 0 ? null : delay;
                              await initializePlayer();
                            }
                          },
                        ),
                      )
                  ],
                ),
              ),
            ),
          );
  }
}

class DelaySlider extends StatefulWidget {
  const DelaySlider({super.key, required this.delay, required this.onSave});

  final int? delay;
  final void Function(int?) onSave;
  @override
  State<DelaySlider> createState() => _DelaySliderState();
}

class _DelaySliderState extends State<DelaySlider> {
  int? delay;
  bool saved = false;

  @override
  void initState() {
    super.initState();
    delay = widget.delay;
  }

  @override
  Widget build(BuildContext context) {
    const int max = 1000;
    return ListTile(
      title: Text(
        "Progress indicator delay ${delay != null ? "${delay.toString()} MS" : ""}",
      ),
      subtitle: Slider(
        value: delay != null ? (delay! / max) : 0,
        onChanged: (value) async {
          delay = (value * max).toInt();
          setState(() {
            saved = false;
          });
        },
      ),
      trailing: IconButton(
        icon: const Icon(Icons.save),
        onPressed: saved
            ? null
            : () {
                widget.onSave(delay);
                setState(() {
                  saved = true;
                });
              },
      ),
    );
  }
}
