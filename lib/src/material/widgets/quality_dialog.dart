import 'package:flutter/material.dart';

class QualityDialog extends StatelessWidget {
  const QualityDialog({
    super.key,
    required List<String> qualities,
    required String selected,
  })  : _qualities = qualities,
        _selected = selected;

  final List<String> _qualities;
  final String _selected;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).primaryColor;

    return ListView.builder(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      itemBuilder: (context, index) {
        final quality = _qualities[index];
        return ListTile(
          dense: true,
          title: Row(
            children: [
              if (quality == _selected)
                Icon(
                  Icons.check,
                  size: 20.0,
                  color: selectedColor,
                )
              else
                Container(width: 20.0),
              const SizedBox(width: 16.0),
              Text(quality),
            ],
          ),
          selected: quality == _selected,
          onTap: () {
            Navigator.of(context).pop(quality);
          },
        );
      },
      itemCount: _qualities.length,
    );
  }
}
