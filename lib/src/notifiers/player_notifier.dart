import 'package:flutter/material.dart';

///
/// The new State-Manager for ChewieLumen!
/// Has to be an instance of Singleton to survive
/// over all State-Changes inside chewieLumen
///
class PlayerNotifier extends ChangeNotifier {
  PlayerNotifier._(
    bool hideStuff,
  ) : _hideStuff = hideStuff;

  bool _hideStuff;

  bool get hideStuff => _hideStuff;

  set hideStuff(bool value) {
    _hideStuff = value;
    notifyListeners();
  }

  // ignore: prefer_constructors_over_static_methods
  static PlayerNotifier init() {
    return PlayerNotifier._(
      true,
    );
  }
}
