import 'dart:js_interop';

import 'package:web/web.dart' as web;

final _handlers = <void Function(), JSFunction>{};

void requestBrowserFullscreen() {
  web.document.documentElement?.requestFullscreen();
}

void exitBrowserFullscreen() {
  if (web.document.fullscreenElement != null) {
    web.document.exitFullscreen();
  }
}

bool get browserInFullscreen => web.document.fullscreenElement != null;

void addBrowserFullscreenChangeListener(void Function() callback) {
  final jsHandler = ((JSAny? _) => callback()).toJS;
  _handlers[callback] = jsHandler;
  web.document.addEventListener('fullscreenchange', jsHandler);
}

void removeBrowserFullscreenChangeListener(void Function() callback) {
  final jsHandler = _handlers.remove(callback);
  if (jsHandler != null) {
    web.document.removeEventListener('fullscreenchange', jsHandler);
  }
}
