import 'package:cast/cast.dart';
import 'package:flutter/material.dart';

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

  set hideStuff(bool value) {
    _hideStuff = value;
    notifyListeners();
  }

  CastSessionState get castState => _castState;

  set castState(CastSessionState value) {
    _castState = value;
    notifyListeners();
  }

  // ignore: prefer_constructors_over_static_methods
  static PlayerNotifier init() {
    return PlayerNotifier._(
      true,
      CastSessionState.closed,
    );
  }
}
