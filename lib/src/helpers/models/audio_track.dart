class AudioTrack {
  AudioTrack({
    this.isDefault,
    this.language,
    this.channels,
    this.groupId,
    this.name,
    this.uri,
  });
  final String? uri;
  final String? name;
  final String? groupId;
  final bool? isDefault;
  final String? language;
  final String? channels;

  AudioTrack copyWith({
    String? language,
    String? channels,
    bool? isDefault,
    String? groupId,
    String? name,
    String? uri,
  }) {
    return AudioTrack(
      uri: uri ?? this.uri,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      language: language ?? this.language,
      channels: channels ?? this.channels,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'AudioTrack(groupId: $groupId, name: $name, isDefault: $isDefault, language: $language, channels: $channels, uri: $uri)';
  }
}
