import 'package:cast/cast.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CastButton extends StatefulWidget {
  const CastButton({
    Key? key,
    required this.onTap,
    this.tintColor,
  }) : super(key: key);

  final Function()? onTap;
  final Color? tintColor;

  @override
  _CastButtonState createState() => _CastButtonState();
}

class _CastButtonState extends State<CastButton> with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<String>? connectingIconTween;
  late Color _tintColor;

  final connectingAssets = [
    "assets/castIcon/cast_1.png",
    "assets/castIcon/cast_2.png",
    "assets/castIcon/cast_3.png",
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tintColor = widget.tintColor ?? Colors.white;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    connectingIconTween = TweenSequence<String>([
      TweenSequenceItem<String>(
        tween: ConstantTween<String>(connectingAssets[0]),
        weight: 34.0,
      ),
      TweenSequenceItem<String>(
        tween: ConstantTween<String>(connectingAssets[1]),
        weight: 33.0,
      ),
      TweenSequenceItem<String>(
        tween: ConstantTween<String>(connectingAssets[2]),
        weight: 33.0,
      ),
    ]).animate(_animationController!);

    for (final path in connectingAssets) {
      Future(() async {
        final globalCache = PaintingBinding.instance!.imageCache;
        final image = ExactAssetImage(path);
        final key = await image.obtainKey(
            createLocalImageConfiguration(context, size: const Size(24, 24)));
        final codec = PaintingBinding.instance!.instantiateImageCodec;
        globalCache!.putIfAbsent(
          key,
          () => image.load(key, codec),
          onError: (e, s) => debugPrint("preload casting asset error"),
        );
      });
    }
    connectingIconTween!.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerNotifier>(
      builder: (context, playerNotifier, w) {
        Widget icon;
        if (playerNotifier.castState == CastSessionState.closed) {
          icon = Icon(Icons.cast, color: _tintColor);
        } else if (playerNotifier.castState == CastSessionState.connected) {
          icon = Icon(Icons.cast_connected, color: _tintColor);
        } else {
          if (_animationController != null) {
            if (!_animationController!.isAnimating) {
              Future.delayed(const Duration(milliseconds: 20), () {
                _animationController?.forward(from: 0.0);
              });
            }
            icon = ImageIcon(
              ExactAssetImage(connectingIconTween!.value),
              size: 24,
              color: _tintColor,
            );
          }
          icon = Icon(Icons.cast, color: _tintColor);
        }
        return IconButton(
          icon: icon,
          onPressed: widget.onTap,
        );
      },
    );
  }
}
