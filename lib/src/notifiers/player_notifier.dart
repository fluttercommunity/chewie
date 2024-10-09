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
    bool showCastControls,
  )   : _hideStuff = hideStuff,
        _showCastControls = showCastControls,
        _lockStuff = lockStuff;

  bool _hideStuff;
  bool _lockStuff;
  bool _showCastControls;

  bool get hideStuff => _hideStuff;

  bool get lockStuff => _lockStuff;

  bool get showCastControls => _showCastControls;

  set hideStuff(bool value) {
    _hideStuff = value;
    notifyListeners();
  }

  set lockStuff(bool value) {
    _lockStuff = value;
    notifyListeners();
  }

  set showCastControls(bool value) {
    _showCastControls = value;
    notifyListeners();
  }

  // ignore: prefer_constructors_over_static_methods
  static PlayerNotifier init() {
    return PlayerNotifier._(
      false,
      false,
      false,
    );
  }
}
