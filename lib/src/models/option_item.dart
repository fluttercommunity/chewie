import 'package:flutter/material.dart';

class OptionItem {
  OptionItem({
    required this.onTap,
    required this.iconData,
    required this.title,
    this.subtitle,
  });

  final void Function(BuildContext context) onTap;
  final IconData iconData;
  final String title;
  final String? subtitle;

  OptionItem copyWith({
    Function(BuildContext context)? onTap,
    IconData? iconData,
    String? title,
    String? subtitle,
  }) {
    return OptionItem(
      onTap: onTap ?? this.onTap,
      iconData: iconData ?? this.iconData,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  String toString() =>
      'OptionItem(onTap: $onTap, iconData: $iconData, title: $title, subtitle: $subtitle)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OptionItem &&
        other.onTap == onTap &&
        other.iconData == iconData &&
        other.title == title &&
        other.subtitle == subtitle;
  }

  @override
  int get hashCode =>
      onTap.hashCode ^ iconData.hashCode ^ title.hashCode ^ subtitle.hashCode;
}
