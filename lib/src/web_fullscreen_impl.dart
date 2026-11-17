import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

extension on web.HTMLVideoElement {
  external bool? get webkitDisplayingFullscreen;
  external void webkitEnterFullscreen();
  external void webkitExitFullscreen();
}

final _handlers = <void Function(), JSFunction>{};
final _videoExitHandlers = <int, JSFunction>{};

/// Whether the document exposes the Fullscreen API.
///
/// iPhone Safari does not: only the video element has `webkitEnterFullscreen`.
/// Calling the missing `requestFullscreen` throws, so callers feature-detect
/// and hand fullscreen to the video element instead of pushing a route.
bool get browserFullscreenSupported {
  final web.Element? element = web.document.documentElement;
  return element != null && (element as JSObject).has('requestFullscreen');
}

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

web.HTMLVideoElement? _videoElement(int playerId) =>
    web.document.getElementById('videoElement-$playerId')
        as web.HTMLVideoElement?;

/// Opens the browser's own fullscreen player for the video element that
/// `video_player_web` created for [playerId]. [onExited] runs when the user
/// closes that player, so the caller can drop its fullscreen state.
void enterVideoElementFullscreen(int playerId, void Function() onExited) {
  final web.HTMLVideoElement? video = _videoElement(playerId);
  if (video == null || !(video as JSObject).has('webkitEnterFullscreen')) {
    return;
  }
  _videoExitHandlers.putIfAbsent(playerId, () {
    final jsHandler = ((JSAny? _) => onExited()).toJS;
    video.addEventListener('webkitendfullscreen', jsHandler);
    return jsHandler;
  });
  video.webkitEnterFullscreen();
}

void exitVideoElementFullscreen(int playerId) {
  final web.HTMLVideoElement? video = _videoElement(playerId);
  if (video != null && (video.webkitDisplayingFullscreen ?? false)) {
    video.webkitExitFullscreen();
  }
}

void disposeVideoElementFullscreen(int playerId) {
  final jsHandler = _videoExitHandlers.remove(playerId);
  if (jsHandler != null) {
    _videoElement(
      playerId,
    )?.removeEventListener('webkitendfullscreen', jsHandler);
  }
}
