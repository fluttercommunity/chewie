import 'package:flutter/foundation.dart';

/// A playback target Chewie can hand the video off to — a Chromecast, an
/// Android TV, a smart TV speaker group.
///
/// Discovered and reported by a [ChewieCastController]; Chewie only ever
/// displays these and passes them back to `connect`.
@immutable
class CastDevice {
  const CastDevice({required this.id, required this.name, this.modelName});

  /// Stable identifier for the device, unique among the devices a single
  /// backend reports. Equality is based on this alone, so it has to survive
  /// a device dropping out of discovery and coming back.
  final String id;

  /// The name to show the user, e.g. `Living Room TV`.
  final String name;

  /// The hardware model, e.g. `Chromecast Ultra`. Shown as a subtitle in the
  /// device picker when present.
  final String? modelName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CastDevice && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CastDevice(id: $id, name: $name, modelName: $modelName)';
}
