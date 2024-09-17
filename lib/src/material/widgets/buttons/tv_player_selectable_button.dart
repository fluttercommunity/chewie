import 'package:chewie/src/config/colors.dart';
import 'package:chewie/src/config/icons.dart';
import 'package:chewie/src/helpers/extensions.dart';
import 'package:chewie/src/widgets/svg/svg_asset.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class TvPlayerSelectableButton extends StatefulWidget {
  const TvPlayerSelectableButton({
    required this.title,
    this.onPressed,
    this.isSelected = false,
    this.autoFocus = false,
    super.key,
  });

  final String title;
  final bool autoFocus;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  State<TvPlayerSelectableButton> createState() =>
      _TvPlayerSelectableButtonState();
}

class _TvPlayerSelectableButtonState extends State<TvPlayerSelectableButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed ?? () {},
        autofocus: widget.autoFocus,
        onFocusChange: (value) {
          setState(() {
            _isFocused = value;
          });
        },
        focusColor: PlayerColors.primary,
        splashColor: PlayerColors.whiteOpacity16,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          decoration: BoxDecoration(
            color: _isFocused ? PlayerColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          padding: EdgeInsets.symmetric(
            vertical: context.vw(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isSelected) Gap(context.vw(4)),
              if (widget.isSelected)
                SvgAsset(
                  PlayerIcons.check,
                  width: context.vw(24),
                  height: context.vw(24),
                  color: _isFocused ? PlayerColors.white : PlayerColors.primary,
                ),
              Gap(context.vw(widget.isSelected ? 4 : 33)),
              Text(
                widget.title,
                style: context.s24Tv.copyWith(
                  color: widget.isSelected && !_isFocused
                      ? PlayerColors.primary
                      : PlayerColors.white,
                ),
              ),
              Gap(context.vw(33)),
            ],
          ),
        ),
      ),
    );
  }
}
