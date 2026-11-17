import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String> fetchText(Uri url) async {
  final response = await web.window.fetch(url.toString().toJS).toDart;
  if (!response.ok) {
    throw StateError('HTTP ${response.status} for $url');
  }
  return (await response.text().toDart).toDart;
}
