import 'dart:convert' show utf8;
import 'dart:typed_data';
import 'package:cast/cast.dart';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_mdns_plugin/flutter_mdns_plugin.dart';

class IOSCastServiceNotifier extends ChangeNotifier {
  IOSCastServiceNotifier() {
    _foundDevices = [];
    _flutterMdnsPlugin = FlutterMdnsPlugin(
      discoveryCallbacks: DiscoveryCallbacks(
        onDiscoveryStarted: () => <void>{},
        onDiscoveryStopped: () => <void>{},
        onDiscovered: (ServiceInfo serviceInfo) => <void>{},
        onResolved: (ServiceInfo serviceInfo) {
          // prevent duplicates
          //debugPrint('found device ${serviceInfo.toString()}');
          if (null != serviceInfo.attr && null != serviceInfo.attr!['fn']) {
            final Uint8List l = Uint8List.fromList(serviceInfo.attr!['fn']!);
            serviceInfo.name = utf8.decode(l);
          }
          final device = CastDevice(
            serviceName: serviceInfo.type,
            name: serviceInfo.name,
            host: serviceInfo.hostName,
            port: serviceInfo.port,
          );
          if (!_foundDevices.contains(device)) _foundDevices.add(device);
          notifyListeners();
        },
      ),
    );
  }

  static late FlutterMdnsPlugin _flutterMdnsPlugin;

  late List<CastDevice> _foundDevices;

  List<CastDevice> get foundDevices => _foundDevices;

  set foundDevices(List<CastDevice> value) {
    _foundDevices = value;
    notifyListeners();
  }

  void startDiscovery() {
    _flutterMdnsPlugin.startDiscovery('_googlecast._tcp');
  }
}
