import 'package:chewie/src/models/video_quality.dart';
import 'package:flutter/material.dart';

/// Lets the user pick one of the available [VideoQuality]s. Pops with the
/// chosen [VideoQuality], or `null` when dismissed.
class VideoQualityDialog extends StatelessWidget {
  const VideoQualityDialog({
    super.key,
    required List<VideoQuality> qualities,
    required Object? selectedId,
  }) : _qualities = qualities,
       _selectedId = selectedId;

  final List<VideoQuality> _qualities;
  final Object? _selectedId;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).primaryColor;

    return ListView(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      children: [
        for (final quality in _qualities)
          ListTile(
            dense: true,
            selected: quality.id == _selectedId,
            onTap: () => Navigator.of(context).pop(quality),
            title: Row(
              children: [
                if (quality.id == _selectedId)
                  Icon(Icons.check, size: 20.0, color: selectedColor)
                else
                  const SizedBox(width: 20.0),
                const SizedBox(width: 16.0),
                Expanded(child: Text(quality.label)),
              ],
            ),
          ),
      ],
    );
  }
}
