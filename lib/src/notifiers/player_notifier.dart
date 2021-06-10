import 'package:flutter/material.dart';

///
/// The new State-Manager for Chewie!
/// Has to be an instance of Singleton to survive
/// over all State-Changes inside chewie
///
class PlayerNotifier extends ChangeNotifier {
  bool _hideStuff = true;

  String? _selectedResolution;

  bool get hideStuff => _hideStuff;

  set hideStuff(bool value) {
    _hideStuff = value;
    notifyListeners();
  }

  String? get selectedResolution => _selectedResolution;

  set selectedResolution(String? value) {
    _selectedResolution = value;
    notifyListeners();
  }
}
