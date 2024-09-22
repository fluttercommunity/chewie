class VideoTrack {
  VideoTrack({
    this.bandwidth,
    this.resolution,
    this.codecs,
    this.audioGroupId,
    this.uri,
    this.programId,
    this.name,
    this.isAuto = false,
  });
  final int? bandwidth;
  final String? resolution;
  final String? codecs;
  final String? audioGroupId;
  final String? uri;
  final int? programId;
  final String? name;
  final bool isAuto;

  VideoTrack copyWith({
    int? bandwidth,
    String? resolution,
    String? codecs,
    String? audioGroupId,
    String? uri,
    int? programId,
    String? name,
    bool? isAuto,
  }) {
    return VideoTrack(
      bandwidth: bandwidth ?? this.bandwidth,
      resolution: resolution ?? this.resolution,
      codecs: codecs ?? this.codecs,
      audioGroupId: audioGroupId ?? this.audioGroupId,
      uri: uri ?? this.uri,
      programId: programId ?? this.programId,
      name: name ?? this.name,
      isAuto: isAuto ?? this.isAuto,
    );
  }

  @override
  String toString() {
    return 'VideoTrack(bandwidth: $bandwidth, resolution: $resolution, codecs: $codecs, audioGroupId: $audioGroupId, uri: $uri, programId: $programId, name: $name)';
  }
}
