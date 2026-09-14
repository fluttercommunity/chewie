import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

/// A control the app hands to Chewie's bar, demonstrating
/// [ChewieController.additionalControls] and [ChewieControlStyle].
///
/// What it does is deliberately trivial — it toggles a bookmark nothing reads.
/// What it shows is the pattern a real control follows: take the surrounding
/// bar's size, tint, padding and chrome rather than hard-coding values that
/// will suit one skin and look wrong in the others.
///
/// Worth trying on all three skins. The same widget draws a 24px glyph on the
/// Material bars, a 16px one on Cupertino's frosted pill, and takes a 48x48
/// tap target on desktop, without being told which bar it landed in. It also
/// fades with the rest of the controls, because it sits inside them.
class DemoBookmarkButton extends StatefulWidget {
  const DemoBookmarkButton({super.key});

  @override
  State<DemoBookmarkButton> createState() => _DemoBookmarkButtonState();
}

class _DemoBookmarkButtonState extends State<DemoBookmarkButton> {
  bool _bookmarked = false;

  @override
  Widget build(BuildContext context) {
    final style = ChewieControlStyle.maybeOf(context);

    final Widget button = GestureDetector(
      onTap: () => setState(() => _bookmarked = !_bookmarked),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          // The bar's padding rather than one of our choosing. A bar is often
          // shorter than its nominal height once the progress bar has taken
          // its share, so padding it does not itself use leaves the glyph less
          // room than it needs and it paints outside its box.
          padding: style?.padding ?? const EdgeInsets.all(8),
          child: Icon(
            _bookmarked ? Icons.bookmark : Icons.bookmark_border,
            size: style?.iconSize ?? 24,
            color: _bookmarked
                ? Theme.of(context).colorScheme.primary
                : style?.iconColor ?? Colors.white,
          ),
        ),
      ),
    );

    // Whatever the bar wraps its own buttons in.
    return style?.decorate(button) ?? button;
  }
}
