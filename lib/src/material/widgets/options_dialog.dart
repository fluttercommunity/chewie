import 'package:chewie/src/material/models/option_item.dart';
import 'package:flutter/material.dart';

class OptionsDialog extends StatefulWidget {
  const OptionsDialog({
    Key? key,
    required this.options,
    this.cancelButtonText,
  }) : super(key: key);

  final List<OptionItem> options;
  final String? cancelButtonText;

  @override
  _OptionsDialogState createState() => _OptionsDialogState();
}

class _OptionsDialogState extends State<OptionsDialog> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: widget.options.length,
            itemBuilder: (context, i) {
              return ListTile(
                onTap: widget.options[i].onTap != null
                    ? widget.options[i].onTap!
                    : null,
                leading: Icon(widget.options[i].iconData),
                title: Text(widget.options[i].title),
                subtitle: widget.options[i].subtitle != null
                    ? Text(widget.options[i].subtitle!)
                    : null,
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              thickness: 1.0,
            ),
          ),
          ListTile(
            onTap: () => Navigator.pop(context),
            leading: const Icon(Icons.close),
            title: Text(
              widget.cancelButtonText ?? 'Cancel',
            ),
          ),
        ],
      ),
    );
  }
}
