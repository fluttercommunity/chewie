import 'package:chewie/src/cast/cast_connection_state.dart';
import 'package:chewie/src/cast/cast_device.dart';
import 'package:chewie/src/cast/chewie_cast_controller.dart';
import 'package:chewie/src/models/cast_translations.dart';
import 'package:flutter/material.dart';

/// The device picker, shown as a modal bottom sheet when the cast button is
/// tapped.
///
/// Rebuilds off the [ChewieCastController] so devices appearing and
/// disappearing mid-scan are reflected live.
class CastDevicesDialog extends StatelessWidget {
  const CastDevicesDialog({
    required this.castController,
    required this.translations,
    this.cancelButtonText,
    super.key,
  });

  final ChewieCastController castController;
  final CastTranslations translations;
  final String? cancelButtonText;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: castController,
      builder: (context, _) {
        final devices = castController.devices;
        final connected = castController.connectedDevice;

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Text(
                    translations.devicesTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (devices.isEmpty) _buildEmptyState(context),
                for (final device in devices)
                  _buildDeviceTile(context, device, connected),
                if (castController.connectionState.isConnected ||
                    castController.connectionState.isTransitioning)
                  ListTile(
                    leading: const Icon(Icons.cast_connected),
                    title: Text(translations.stopCastingText),
                    onTap: () {
                      Navigator.pop(context);
                      castController.disconnect();
                    },
                  ),
                if (cancelButtonText != null)
                  ListTile(
                    title: Text(cancelButtonText!),
                    onTap: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // While a scan is running, an empty list means "not found yet", not "none
    // exist" — saying "no devices found" there would be wrong for the first
    // couple of seconds of every scan.
    final searching = castController.isDiscovering;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        children: [
          if (searching)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.cast, size: 16),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              searching
                  ? translations.searchingText
                  : translations.noDevicesText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(
    BuildContext context,
    CastDevice device,
    CastDevice? connected,
  ) {
    final isCurrent = device == connected;
    final isConnecting =
        isCurrent && castController.connectionState.isTransitioning;

    return ListTile(
      leading: Icon(isCurrent ? Icons.cast_connected : Icons.cast),
      title: Text(device.name),
      subtitle: isConnecting
          ? Text(translations.connectingText)
          : device.modelName != null
          ? Text(device.modelName!)
          : null,
      trailing: isConnecting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      selected: isCurrent,
      onTap: isCurrent
          ? null
          : () {
              Navigator.pop(context);
              castController.connect(device);
            },
    );
  }
}
