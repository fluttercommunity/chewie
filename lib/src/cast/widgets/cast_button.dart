import 'package:chewie/src/cast/cast_connection_state.dart';
import 'package:chewie/src/cast/chewie_cast_controller.dart';
import 'package:chewie/src/cast/widgets/cast_devices_dialog.dart';
import 'package:chewie/src/cast/widgets/cupertino_cast_devices_sheet.dart';
import 'package:chewie/src/models/cast_translations.dart';
import 'package:flutter/cupertino.dart' show showCupertinoModalPopup;
import 'package:flutter/material.dart';

/// How [CastButton] presents its device picker.
enum CastPickerStyle {
  /// A Material modal bottom sheet of `ListTile`s.
  material,

  /// A `CupertinoActionSheet`, as iOS presents a choice.
  cupertino,
}

/// The cast button for Chewie's control bars.
///
/// Shows the idle cast glyph when there is no session, a pulsing one while
/// connecting, and the connected glyph once the receiver has the stream.
/// Tapping it opens the device picker; discovery runs only while that sheet is
/// open, so an idle player is not scanning the network forever.
class CastButton extends StatefulWidget {
  const CastButton({
    required this.castController,
    required this.translations,
    this.iconColor = Colors.white,
    this.iconSize,
    this.padding,
    this.useRootNavigator = true,
    this.pickerStyle = CastPickerStyle.material,
    this.cancelButtonText,
    this.onMenuOpened,
    this.onMenuClosed,
    super.key,
  });

  final ChewieCastController castController;
  final CastTranslations translations;
  final Color iconColor;
  final double? iconSize;
  final EdgeInsets? padding;
  final bool useRootNavigator;

  /// Which picker the button opens; set by the skin that hosts it.
  final CastPickerStyle pickerStyle;
  final String? cancelButtonText;

  /// Called as the picker opens, so the skin can hold its hide timer.
  final VoidCallback? onMenuOpened;

  /// Called once the picker is dismissed.
  final VoidCallback? onMenuClosed;

  @override
  State<CastButton> createState() => _CastButtonState();
}

class _CastButtonState extends State<CastButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    widget.castController.addListener(_onCastChanged);
    _syncPulse();
  }

  @override
  void didUpdateWidget(CastButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.castController != widget.castController) {
      oldWidget.castController.removeListener(_onCastChanged);
      widget.castController.addListener(_onCastChanged);
      _syncPulse();
    }
  }

  @override
  void dispose() {
    widget.castController.removeListener(_onCastChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onCastChanged() {
    if (!mounted) return;
    setState(_syncPulse);
  }

  void _syncPulse() {
    if (widget.castController.connectionState.isTransitioning) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else if (_pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..value = 1.0;
    }
  }

  Future<void> _openPicker() async {
    widget.onMenuOpened?.call();
    // Only scan while the user is looking at the list.
    await widget.castController.startDiscovery();

    if (!mounted) {
      // Never leave a scan running for a picker that will never open.
      await widget.castController.stopDiscovery();
      return;
    }
    switch (widget.pickerStyle) {
      case CastPickerStyle.material:
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: widget.useRootNavigator,
          builder: (_) => CastDevicesDialog(
            castController: widget.castController,
            translations: widget.translations,
            cancelButtonText: widget.cancelButtonText,
          ),
        );
      case CastPickerStyle.cupertino:
        await showCupertinoModalPopup<void>(
          context: context,
          useRootNavigator: widget.useRootNavigator,
          builder: (_) => CupertinoCastDevicesSheet(
            castController: widget.castController,
            translations: widget.translations,
            cancelButtonText: widget.cancelButtonText,
          ),
        );
    }

    await widget.castController.stopDiscovery();
    widget.onMenuClosed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.castController.connectionState;
    final icon = Icon(
      state.isConnected ? Icons.cast_connected : Icons.cast,
      color: widget.iconColor,
      size: widget.iconSize,
    );

    return Tooltip(
      message: widget.translations.castButtonTooltip,
      child: GestureDetector(
        onTap: _openPicker,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(12.0),
            child: state.isTransitioning
                ? FadeTransition(
                    opacity: Tween<double>(
                      begin: 0.35,
                      end: 1.0,
                    ).animate(_pulseController),
                    child: icon,
                  )
                : icon,
          ),
        ),
      ),
    );
  }
}
