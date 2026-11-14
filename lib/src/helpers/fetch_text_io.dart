import 'dart:convert';
import 'dart:io';

Future<String> fetchText(Uri url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    return await response
        .transform(const Utf8Decoder(allowMalformed: true))
        .join();
  } finally {
    client.close();
  }
}
