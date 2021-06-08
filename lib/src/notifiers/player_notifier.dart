import 'package:cast/cast.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

///
/// The new State-Manager for Chewie!
/// Has to be an instance of Singleton to survive
/// over all State-Changes inside chewie
///
class PlayerNotifier extends ChangeNotifier {
  PlayerNotifier._(
    bool hideStuff,
    CastSessionState castState,
  )   : _hideStuff = hideStuff,
        _castState = castState;

  bool _hideStuff;

  CastSessionState _castState;

  bool get hideStuff => _hideStuff;
  CastSessionState get castState => _castState;

  set hideStuff(bool value) {
    _hideStuff = value;
    notifyListeners();
  }

  set castState(CastSessionState value) {
    _castState = value;
    notifyListeners();
  }

  Future<void> connectToCastDevice(
    ChewieController controller,
    CastDevice device,
  ) async {
    final session = await CastSessionManager().startSession(device);

    session.stateStream.listen((state) {
      _castState = state;
      if (state == CastSessionState.connected) {
        //debugPrint('_sendMessagePlayVideo');

        final message = {
          // Here you can plug an URL to any mp4, webm, mp3 or jpg file with the proper contentType.
          'contentId': controller.videoPlayerController.dataSource,
          'contentType':
              lookupMimeType(controller.videoPlayerController.dataSource),
          'streamType': controller.isLive ? 'LIVE' : 'BUFFERED',

          // Title and cover displayed while buffering
          'metadata': {
            'type': 0,
            'metadataType': 0,
            'title': 'Chewie Cast',
            'images': [
              {
                'url':
                    'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg'
              }
            ]
          }
        };

        session.sendMessage(
          CastSession.kNamespaceMedia,
          <String, dynamic>{
            'type': 'LOAD',
            'autoPlay': true,
            'currentTime': 0,
            'media': message,
          },
        );
      }
    });

    session.messageStream.listen((message) {
      //debugPrint('receive message: $message');
    });
  }

  // ignore: prefer_constructors_over_static_methods
  static PlayerNotifier init() {
    return PlayerNotifier._(
      true,
      CastSessionState.closed,
    );
  }
}
