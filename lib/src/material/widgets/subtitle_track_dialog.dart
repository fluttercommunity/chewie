import 'package:chewie/src/models/subtitle_track.dart';
import 'package:flutter/material.dart';

/// The user's pick from a [SubtitleTrackDialog].
///
/// Wrapping the track lets callers tell "the user chose Off" ([track] is
/// `null`) apart from "the dialog was dismissed" (the dialog pops `null`).
class SubtitleTrackChoice {
  const SubtitleTrackChoice(this.track);

  /// The selected track, or `null` when the user picked "Off".
  final SubtitleTrack? track;
}

/// Lets the user pick one of the available [SubtitleTrack]s, or turn subtitles
/// off. Pops with a [SubtitleTrackChoice], or `null` when dismissed.
class SubtitleTrackDialog extends StatelessWidget {
  const SubtitleTrackDialog({
    super.key,
    required List<SubtitleTrack> tracks,
    required Object? selectedId,
    this.offLabel = 'Off',
  }) : _tracks = tracks,
       _selectedId = selectedId;

  final List<SubtitleTrack> _tracks;
  final Object? _selectedId;
  final String offLabel;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).primaryColor;

    Widget tile({
      required bool selected,
      required String label,
      String? trailing,
      required VoidCallback onTap,
    }) {
      return ListTile(
        dense: true,
        selected: selected,
        onTap: onTap,
        title: Row(
          children: [
            if (selected)
              Icon(Icons.check, size: 20.0, color: selectedColor)
            else
              const SizedBox(width: 20.0),
            const SizedBox(width: 16.0),
            Expanded(child: Text(label)),
            if (trailing != null)
              Text(trailing, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      children: [
        tile(
          selected: _selectedId == null,
          label: offLabel,
          onTap: () =>
              Navigator.of(context).pop(const SubtitleTrackChoice(null)),
        ),
        for (final track in _tracks)
          tile(
            selected: track.id == _selectedId,
            label: track.label,
            trailing: track.language,
            onTap: () => Navigator.of(context).pop(SubtitleTrackChoice(track)),
          ),
      ],
    );
  }
}
