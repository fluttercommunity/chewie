import 'package:flutter/material.dart';

class PlayerAnimation extends StatefulWidget {
  const PlayerAnimation({
    required this.child,
    required this.value,
    this.duration = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
    this.disableScale = false,
    super.key,
  });

  final bool value;
  final Widget child;
  final bool disableScale;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  State<PlayerAnimation> createState() => _PlayerAnimationState();
}

class _PlayerAnimationState extends State<PlayerAnimation>
    with TickerProviderStateMixin {
  Offset initialOffset = Offset.zero;

  late final animationController = AnimationController(
    duration: widget.duration,
    vsync: this,
  );

  late final animationValue = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(
    CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ),
  );

  late Animation<Offset> animationOffset;

  @override
  void initState() {
    switch (widget.alignment) {
      case Alignment.topCenter:
        initialOffset = const Offset(0, -200);
      case Alignment.bottomCenter:
        initialOffset = const Offset(0, 200);
      case Alignment.centerLeft:
        initialOffset = const Offset(-100, 0);
      case Alignment.centerRight:
        initialOffset = const Offset(100, 0);
    }

    animationOffset = Tween<Offset>(
      begin: initialOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.ease,
      ),
    );

    setState(() {});

    super.initState();
  }

  @override
  void didUpdateWidget(covariant PlayerAnimation oldWidget) {
    if (widget.value) {
      animationController.forward();
    } else {
      animationController.reverse();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.value ? 1 : 0,
      duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 2),
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: animationOffset.value,
            child: widget.disableScale
                ? child
                : Transform.scale(
                    scale: 1.333 - animationValue.value / 3,
                    alignment: widget.alignment,
                    child: child,
                  ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
