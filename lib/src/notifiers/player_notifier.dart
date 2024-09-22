import 'package:flutter/material.dart';

///
/// The new State-Manager for Chewie!
/// Has to be an instance of Singleton to survive
/// over all State-Changes inside chewie
///
class PlayerNotifier extends ChangeNotifier {
  PlayerNotifier._(
    bool hideStuff,
    bool lockStuff,
  )   : _hideStuff = hideStuff,
        _lockStuff = lockStuff;

  bool _hideStuff;
  bool _lockStuff;

  bool get hideStuff => _hideStuff;

  bool get lockStuff => _lockStuff;

  set hideStuff(bool value) {
    _hideStuff = value;
    notifyListeners();
  }

  set lockStuff(bool value) {
    _lockStuff = value;
    notifyListeners();
  }

  // ignore: prefer_constructors_over_static_methods
  static PlayerNotifier init() {
    return PlayerNotifier._(
      false,
      false,
    );
  }
}
