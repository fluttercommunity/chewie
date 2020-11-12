/* pars format
*
* 1
* 00:00:19,063 --> 00:00:21,297
* Hello World
*
* */

class Subtitles {
  Subtitles(this.subtitle);

  Subtitles.fromString(String value) : subtitle = parseString(value);

  final List<Subtitle> subtitle;

  static List<Subtitle> parseString(String value) {
    List<String> components = value.split('\r\n\r\n');
    if (components.length == 1) {
      components = value.split('\n\n');
    }

    final List<Subtitle> subtitlesObj = List();

    for (var component in components) {
      if (component.isEmpty) {
        continue;
      }

      final subtitle = Subtitle(component);
      if (subtitle != null) {
        subtitlesObj.add(subtitle);
      }
    }

    return subtitlesObj;
  }

  bool get isEmpty => subtitle.isEmpty;

  bool get isNotEmpty => !isEmpty;

  List<Subtitle> getByPosition(Duration position) {
    final found = subtitle.where((item) {
      if (item != null) return position >= item.start && position <= item.end;
      return false;
    }).toList();

    return found;
  }
}

class Subtitle {
  factory Subtitle(String value) {
    final scanner = value.split('\n');
    if (scanner.length < 3) {
      return null;
    }
    if (scanner[0].isEmpty) {
      scanner.removeAt(0);
    }
    final index = int.parse(scanner[0]);
    final start = stringToDuration(scanner[1].split(timerSeparator)[0]);
    final end = stringToDuration(scanner[1].split(timerSeparator)[1]);
    final texts = scanner.sublist(2, scanner.length);

    return Subtitle._(index: index, start: start, end: end, texts: texts);
  }

  Subtitle._({this.index, this.start, this.end, this.texts});

  static const String timerSeparator = ' --> ';
  final int index;
  final Duration start;
  final Duration end;
  final List<String> texts;

  static Duration stringToDuration(String value) {
    final component = value.split(':');

    if (component.length < 4) {
      return Duration(
        hours: int.parse(component[0]),
        minutes: int.parse(component[1]),
        seconds: int.parse(component[2]),
      );
    } else {
      return Duration(
        hours: int.parse(component[0]),
        minutes: int.parse(component[1]),
        seconds: int.parse(component[2].split('.')[0]),
        milliseconds: int.parse(component[2].split('.')[1]),
      );
    }
  }
}
