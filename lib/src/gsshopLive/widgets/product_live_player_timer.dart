import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

class ProductLivePlayerTimer extends StatefulWidget {
  const ProductLivePlayerTimer({
    Key? key,
    required this.leftTime,
    required this.show,
  }) : super(key: key);

  final String leftTime;
  final bool show;

  @override
  _ProductLivePlayerTimerState createState() => _ProductLivePlayerTimerState();
}

class _ProductLivePlayerTimerState extends State<ProductLivePlayerTimer> {
  Timer? _timer;
  late String timeLabelText;
  late Duration diff;

  @override
  void didUpdateWidget(covariant ProductLivePlayerTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  String timeDiffToString(diff) {
    return diff.toString().split('.')[0].padLeft(8, '0');
  }

  DateTime timeParser(String time) {
    final yyyymmdd = time.substring(0, 8);
    final hhmmss = time.substring(8, 14);
    return DateTime.parse('${yyyymmdd}T$hhmmss');
  }

  @override
  void initState() {
    super.initState();

    timeLabelText = widget.leftTime != null ? '00:00:00' : '';

    /* 1회성 호출 00:00:00 처리 */
    if (widget.leftTime != null) {
      var endTime = timeParser(widget.leftTime!);
      var current = DateTime.now();
      diff = endTime.difference(current);

      if (diff.inSeconds <= 0) {
        if (mounted) {
          setState(() {
            timeLabelText = '방송이 종료되었습니다.';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            timeLabelText = timeDiffToString(diff);
          });
        }

        /* 1초간격 Time 표시 */
        const oneSec = Duration(seconds: 1);

        _timer = Timer.periodic(
          oneSec,
          (Timer t) {
            endTime = timeParser(widget.leftTime!);
            current = DateTime.now();
            diff = endTime.difference(current);

            if (diff.inSeconds <= 0) {
              if (mounted) {
                setState(() {
                  timeLabelText = '방송이 종료되었습니다.';
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  timeLabelText = (timeDiffToString(diff));
                });
              }
            }
          },
        );
      }
    }
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Text(
        timeLabelText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontFamily: 'Pretendard',
          fontStyle: FontStyle.normal,
          fontSize: 20.0,
          fontFeatures: [FontFeature.tabularFigures()],
          shadows: <Shadow>[
            Shadow(
                offset: Offset(0.0, 4.0),
                blurRadius: 20.0,
                color: Color.fromARGB(8, 0, 0, 0))
          ],
        ),
      ),
    );
  }
}
