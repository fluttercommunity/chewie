enum BadgeType {
  player(right: 6, top: 10, widgetHeight: 10, widgetWidth: 19),
  sheetTile(top: 0, right: 0, widgetHeight: 7.5, widgetWidth: 14.25);

  const BadgeType({
    required this.top,
    required this.right,
    required this.widgetHeight,
    required this.widgetWidth,
  });

  final double top;
  final double right;
  final double widgetHeight;
  final double widgetWidth;
}
