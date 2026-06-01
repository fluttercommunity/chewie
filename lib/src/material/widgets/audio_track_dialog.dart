import 'package:chewie/src/models/audio_track.dart';
import 'package:flutter/material.dart';

/// Lets the user pick one of the available [AudioTrack]s. Pops with the chosen
/// [AudioTrack], or `null` when dismissed. Unlike subtitles there is no "off"
/// option — one audio track is always active.
class AudioTrackDialog extends StatelessWidget {
  const AudioTrackDialog({
    super.key,
    required List<AudioTrack> tracks,
    required Object? selectedId,
  }) : _tracks = tracks,
       _selectedId = selectedId;

  final List<AudioTrack> _tracks;
  final Object? _selectedId;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).primaryColor;

    return ListView(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      children: [
        for (final track in _tracks)
          ListTile(
            dense: true,
            selected: track.id == _selectedId,
            onTap: () => Navigator.of(context).pop(track),
            title: Row(
              children: [
                if (track.id == _selectedId)
                  Icon(Icons.check, size: 20.0, color: selectedColor)
                else
                  const SizedBox(width: 20.0),
                const SizedBox(width: 16.0),
                Expanded(child: Text(track.label)),
                if (track.language != null)
                  Text(
                    track.language!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
