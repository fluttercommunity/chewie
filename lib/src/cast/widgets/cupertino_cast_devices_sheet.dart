import 'package:chewie/src/cast/cast_connection_state.dart';
import 'package:chewie/src/cast/cast_device.dart';
import 'package:chewie/src/cast/chewie_cast_controller.dart';
import 'package:chewie/src/models/cast_translations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

/// The device picker as a [CupertinoActionSheet], for the Cupertino skin.
///
/// Same content as `CastDevicesDialog`, presented the way iOS presents a
/// choice: an action sheet from the bottom rather than a Material modal sheet
/// of `ListTile`s.
///
/// Rebuilds off the [ChewieCastController] so devices appearing and
/// disappearing mid-scan are reflected live.
class CupertinoCastDevicesSheet extends StatelessWidget {
  const CupertinoCastDevicesSheet({
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
        final state = castController.connectionState;

        return CupertinoActionSheet(
          title: Text(translations.devicesTitle),
          message: devices.isEmpty ? _buildEmptyState() : null,
          actions: [
            for (final device in devices)
              _buildDeviceAction(context, device, connected),
            if (state.isConnected || state.isTransitioning)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  castController.disconnect();
                },
                child: Text(translations.stopCastingText),
              ),
          ],
          cancelButton: cancelButtonText == null
              ? null
              : CupertinoActionSheetAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(context),
                  child: Text(cancelButtonText!),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    // While a scan is running, an empty list means "not found yet", not "none
    // exist" — saying "no devices found" there would be wrong for the first
    // couple of seconds of every scan.
    final searching = castController.isDiscovering;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (searching)
          const CupertinoActivityIndicator(radius: 8)
        else
          const Icon(Icons.cast, size: 16),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            searching ? translations.searchingText : translations.noDevicesText,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceAction(
    BuildContext context,
    CastDevice device,
    CastDevice? connected,
  ) {
    final isCurrent = device == connected;
    final isConnecting =
        isCurrent && castController.connectionState.isTransitioning;

    // The glyph matches the cast button's own, rather than switching to
    // CupertinoIcons, so the sheet reads as belonging to the button that
    // opened it.
    final subtitle = isConnecting
        ? translations.connectingText
        : device.modelName;

    return CupertinoActionSheetAction(
      // Connecting to the device already selected would restart the session.
      onPressed: isCurrent
          ? () {}
          : () {
              Navigator.pop(context);
              castController.connect(device);
            },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isCurrent ? Icons.cast_connected : Icons.cast, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(device.name),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: CupertinoTheme.of(
                      context,
                    ).textTheme.tabLabelTextStyle,
                  ),
              ],
            ),
          ),
          if (isConnecting) ...[
            const SizedBox(width: 10),
            const CupertinoActivityIndicator(radius: 8),
          ],
        ],
      ),
    );
  }
}
