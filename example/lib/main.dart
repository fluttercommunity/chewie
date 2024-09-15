import 'dart:io';

import 'package:chewie_example/app/app.dart';
import 'package:flutter/material.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ByteData data = await PlatformAssetBundle().load('assets/cer/cert.pem');
  // SecurityContext.defaultContext
  // .setTrustedCertificatesBytes(data.buffer.asUint8List());
  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const ChewieDemo(),
      },
    ),
  );
}
