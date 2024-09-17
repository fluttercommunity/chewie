import 'package:chewie/src/config/colors.dart';
import 'package:chewie/src/helpers/extensions.dart';
import 'package:chewie/src/widgets/animations/player_animated_size.dart';
import 'package:chewie/src/widgets/svg/svg_asset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

class TvPlayerIconButton extends StatefulWidget {
  const TvPlayerIconButton({
    required this.onTap,
    this.title,
    this.icon,
    super.key,
  });

  final String? icon;
  final String? title;
  final VoidCallback onTap;

  @override
  State<TvPlayerIconButton> createState() => _TvPlayerIconButtonState();
}

class _TvPlayerIconButtonState extends State<TvPlayerIconButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (value) {
          setState(() {
            _isFocused = value;
          });
        },
        focusColor: PlayerColors.primary,
        splashColor: PlayerColors.whiteOpacity16,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          height: context.vw(64),
          padding: EdgeInsets.symmetric(
            horizontal: context.vw(widget.title != null ? 24 : 12),
            vertical: context.vw(12),
          ),
          decoration: BoxDecoration(
            color:
                _isFocused ? PlayerColors.primary : PlayerColors.whiteOpacity16,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null)
                  SvgAsset(
                    widget.icon.toString(),
                    color:
                        _isFocused ? PlayerColors.white : PlayerColors.greyB8,
                    width: context.vw(40),
                    height: context.vw(40),
                  ),
                if (widget.title != null)
                  PlayerAnimatedSize(
                    value: _isFocused,
                    duration: 200.ms,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Gap(
                          context.vw(8),
                        ),
                        Text(
                          widget.title.toString(),
                          style: context.s24Tv.copyWith(
                            color: _isFocused
                                ? PlayerColors.white
                                : PlayerColors.greyB8,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
