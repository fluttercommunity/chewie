/// Strings shown by Chewie's casting UI.
///
/// Separate from `OptionsTranslation`, which covers the options sheet, so that
/// apps without casting never see these and apps with casting get one place to
/// localise.
class CastTranslations {
  const CastTranslations({
    this.castButtonTooltip = 'Cast',
    this.devicesTitle = 'Cast to',
    this.searchingText = 'Looking for devices…',
    this.noDevicesText = 'No devices found',
    this.connectingText = 'Connecting…',
    this.castingToText = 'Casting to',
    this.stopCastingText = 'Stop casting',
  });

  /// Tooltip on the cast button in the control bar.
  final String castButtonTooltip;

  /// Header of the device picker sheet.
  final String devicesTitle;

  /// Shown in the picker while discovery is running and nothing has been found
  /// yet.
  final String searchingText;

  /// Shown in the picker once discovery has finished with no receivers.
  final String noDevicesText;

  /// Shown while a session is being established.
  final String connectingText;

  /// Prefix on the casting overlay, followed by the device name.
  final String castingToText;

  /// Label of the disconnect row in the picker.
  final String stopCastingText;

  CastTranslations copyWith({
    String? castButtonTooltip,
    String? devicesTitle,
    String? searchingText,
    String? noDevicesText,
    String? connectingText,
    String? castingToText,
    String? stopCastingText,
  }) {
    return CastTranslations(
      castButtonTooltip: castButtonTooltip ?? this.castButtonTooltip,
      devicesTitle: devicesTitle ?? this.devicesTitle,
      searchingText: searchingText ?? this.searchingText,
      noDevicesText: noDevicesText ?? this.noDevicesText,
      connectingText: connectingText ?? this.connectingText,
      castingToText: castingToText ?? this.castingToText,
      stopCastingText: stopCastingText ?? this.stopCastingText,
    );
  }
}
