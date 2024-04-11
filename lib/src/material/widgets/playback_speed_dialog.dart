import 'package:flutter/material.dart';

class PlaybackSpeedDialog extends StatelessWidget {
  const PlaybackSpeedDialog({
    super.key,
    required List<double> speeds,
    required double selected,
  })  : _speeds = speeds,
        _selected = selected;

  final List<double> _speeds;
  final double _selected;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).primaryColor;

    return ListView.builder(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      itemBuilder: (context, index) {
        final speed = _speeds[index];
        return ListTile(
          dense: true,
          title: Row(
            children: [
              if (speed == _selected)
                Icon(
                  Icons.check,
                  size: 20.0,
                  color: selectedColor,
                )
              else
                Container(width: 20.0),
              const SizedBox(width: 16.0),
              Text(speed.toString()),
            ],
          ),
          selected: speed == _selected,
          onTap: () {
            Navigator.of(context).pop(speed);
          },
        );
      },
      itemCount: _speeds.length,
    );
  }
}
