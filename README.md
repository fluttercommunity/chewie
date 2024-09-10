# chewie

[![Flutter Community: chewie](https://fluttercommunity.dev/_github/header/chewie)](https://github.com/fluttercommunity/community)

[![Version](https://img.shields.io/pub/v/chewie.svg)](https://pub.dev/packages/chewie)
![CI](https://github.com/brianegan/chewie/workflows/CI/badge.svg)
[![Generic badge](https://img.shields.io/badge/platform-android%20|%20ios%20|%20web%20-blue.svg)](https://pub.dev/packages/chewie)

The video player for Flutter with a heart of gold. 

The [`video_player`](https://pub.dartlang.org/packages/video_player) plugin provides low-level access to video playback. Chewie uses the `video_player` under the hood and wraps it in a friendly Material or Cupertino UI!

## Preview

| MaterialControls | MaterialDesktopControls |
| :--------------: | :---------------------: |
|     ![](https://github.com/brianegan/chewie/raw/master/assets/MaterialControls.png)     |    ![](https://github.com/brianegan/chewie/raw/master/assets/MaterialDesktopControls.png)     |

### CupertinoControls
![](https://github.com/brianegan/chewie/raw/master/assets/CupertinoControls.png)

## Installation

In your `pubspec.yaml` file within your Flutter Project add `chewie` and `video_player` under dependencies:

```yaml
dependencies:
  chewie: <latest_version>
  video_player: <latest_version>
```

## Using it

```dart
import 'package:chewie/chewie.dart';
final videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'));

await videoPlayerController.initialize();

final chewieController = ChewieController(
  videoPlayerController: videoPlayerController,
  autoPlay: true,
  looping: true,
);

final playerWidget = Chewie(
  controller: chewieController,
);
```

Please make sure to dispose both controller widgets after use. For example, by overriding the dispose method of the a `StatefulWidget`:
```dart
@override
void dispose() {
  videoPlayerController.dispose();
  chewieController.dispose();
  super.dispose();
}
```

## Options

![](https://github.com/brianegan/chewie/raw/master/assets/Options.png)

Chewie has some options which control the video. These options appear by default in a `showModalBottomSheet` (similar to YT). By default, Chewie passes  `Playback speed` and `Subtitles` options as an `OptionItem`.

To add additional options, just add these lines to your `ChewieController`:

```dart
additionalOptions: (context) {
  return <OptionItem>[
    OptionItem(
      onTap: () => debugPrint('My option works!'),
      iconData: Icons.chat,
      title: 'My localized title',
    ),
    OptionItem(
      onTap: () =>
          debugPrint('Another option that works!'),
      iconData: Icons.chat,
      title: 'Another localized title',
    ),
  ];
},
```

### Customizing the modal sheet

If you don't like the default `showModalBottomSheet` for showing your options, you can override the View with the `optionsBuilder` method:

```dart
optionsBuilder: (context, defaultOptions) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        content: ListView.builder(
          itemCount: defaultOptions.length,
          itemBuilder: (_, i) => ActionChip(
            label: Text(defaultOptions[i].title),
            onPressed: () =>
                defaultOptions[i].onTap!(),
          ),
        ),
      );
    },
  );
},
```

Your `additionalOptions` are already included here (if you provided `additionalOptions`)!

### Translations

What is an option without proper translation? 

To add your translation strings add:

```dart
optionsTranslation: OptionsTranslation(
  playbackSpeedButtonText: 'Wiedergabegeschwindigkeit',
  subtitlesButtonText: 'Untertitel',
  cancelButtonText: 'Abbrechen',
),
```

## Subtitles

> Since version 1.1.0 chewie supports subtitles. Here you can see how to use them.

You can provide an `List<Subtitle>` and customize your subtitles with the `subtitleBuilder` function.

Add subtitles to your `ChewieController` like the following example:

```dart
ChewieController(
  videoPlayerController: _videoPlayerController,
  autoPlay: true,
  looping: true,
  subtitle: Subtitles([
    Subtitle(
      index: 0,
      start: Duration.zero,
      end: const Duration(seconds: 10),
      text: 'Hello from subtitles',
    ),
    Subtitle(
      index: 1,
      start: const Duration(seconds: 10),
      end: const Duration(seconds: 20),
      text: 'Whats up? :)',
    ),
  ]),
  subtitleBuilder: (context, subtitle) => Container(
    padding: const EdgeInsets.all(10.0),
    child: Text(
      subtitle,
      style: const TextStyle(color: Colors.white),
    ),
  ),
);
```

The `index` attribute is for if you want to structure your subtitles in your database and provide your indexes here. `end` and `text` are the key attributes. 

The Duration defines which part of your video your subtitles should start and end. For example, if your video is 10 minutes long and you want to add a subtitle between: `00:00` and `00:10`'th of a second:

```dart
Subtitle(
  index: 0,
  start: Duration.zero,
  end: const Duration(seconds: 10),
  text: 'Hello from subtitles',
),
```

## Example

Please run the app in the [`example/`](https://github.com/brianegan/chewie/tree/master/example) folder to start playing!

## Migrating from Chewie < 0.9.0

Instead of passing the `VideoPlayerController` and your options to the `Chewie` widget you now pass them to the `ChewieController` and pass that later to the `Chewie` widget.

```dart
final playerWidget = Chewie(
  videoPlayerController,
  autoPlay: true,
  looping: true,
);
```

becomes

```dart
final chewieController = ChewieController(
  videoPlayerController: videoPlayerController,
  autoPlay: true,
  looping: true,
);

final playerWidget = Chewie(
  controller: chewieController,
);
```

## Roadmap

- [x] MaterialUI
- [x] MaterialDesktopUI
- [x] CupertinoUI
- [x] Options with translations
- [x] Subtitles
- [x] CustomControls
- [x] Auto-Rotate on FullScreen depending on Source Aspect-Ratio
- [x] Live-Stream and UI
- [x] AutoPlay
- [x] Placeholder
- [x] Looping
- [x] Start video at
- [x] Custom Progress-Bar colors
- [x] Custom Overlay
- [x] Allow Sleep (Wakelock)
- [x] Playbackspeed Control 
- [x] Custom Route-Pagebuilder
- [x] Custom Device-Orientation and SystemOverlay before and after fullscreen
- [x] Custom ErrorBuilder
- [ ] Support different resolutions of video
- [ ] Re-design State-Manager with Provider
- [ ] Screen-Mirroring / Casting (Google Chromecast)


## iOS warning 

The video_player plugin used by chewie will only work in iOS simulators if you are on flutter 1.26.0 or above. You may need to switch to the beta channel `flutter channel beta`
Please refer to this [issue](https://github.com/flutter/flutter/issues/14647).



```
000000000000000KKKKKKKKKKKKXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKK00
000000000000000KKKKKKKKKKKKKXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00
000000000000000KKKKKKKKKKKKKXXXXXXK0xdoddoclodxOKKKKKKKKKKKKKKKKKKK00
00000000000000KKKKKKKKKKKKKKKK0xoc:;;,;,,,,''';cldxO0KKKKKKKKKKKKK000
00000000000000KKKKKKKKKKKKKKx:'',,,'.,'...;,'''',;:clk0KKKKKKKKKKK000
00000000000000KKKKKKKKKKKKd;'',,,;;;'.,..,c;;,;;;;;:;;d0KKKKKKKKKK000
00000000000000KKKKKKKKKKx,',;:ccl;,c;';,,ol::coolc:;;,,x0KKKKKKKKK000
00000000000000KKKKKKKKOl;:;:clllll;;o;;;cooclddclllllc::kKKKKKKKKK000
00000000000000KKKKKK0o;:ccclccccooo:ooc:ddoddloddolc;;;:c0KKKKKKK0000
00000000000000KKKKKOccodolccclllooddddddxdxddxkkkkxxo;'';d0KKKKKK0000
00000000000000KKKKkcoddolllllclloodxxxxdddxdddxxxddool:'.;O0KKKKK0000
00000000000000000xloollcccc:cclclodkkxxxdddxxxkkxdlllolc,,x0KKKKK0000
0000000000000000xccllccccc:;,'',;:dxkxxddddxkkkxdollcc:cc;d0KKKKKK000
000000000000000kcc:::cllol:'......odxxdoccldxxxdollllc:;;:d0KKKKK0000
00000000000000klc;;;clcc::;'...';;;:cll..',cdddolccccccc;:x0KKKKK0000
0000000000000kdl;:cclllclllc::;,;.'.''o;,,'.;ccoooollllc:;x0KKKKK0000
000000000000kol;:;::coolcc:::,.....,..cd,....':lolclolllc;x0KKKK00000
00000000000Odl;:'cllol;''',;;;;::''.',:doc;,',::looc:lcol:x0K00000000
0000000000Oxl:c,:lolc,..',:clllollodoc;cllolccloolllcclollO0K00000000
0000000000xllc,:lool:'.,...o.;llxdo:loc;;ccodlolodldllolld00K0K000000
000000000Ooc::coooc,,.',;:lx,,...':;o;l;':o:oolccocdoldloO0000KK00000
00000000kol:clllc;;,.;::;:clllllolxc;.:c':ocldlccl;clldox000000000000
000000Odll:cccc;:;,';cllooodoollcloll;c:.:d:ooo;cl;oloddkO00000000000
0000OOddOdll;c,;;,,;;:cldodddoxdoodlcc:.,ox:o:lllocdlodx00O0000000000
000Oxdl:::ll,:,:;,';c,:oloddolkxddxolc.'coccocolcccoooc;oxO00KOOOO000
dc;,'...';c,,:c:::'c:';cldoo;:odolxoc:.,o:oldlxol;lddl,.,lkO0KdlcckKO
'.......,:''';cll:cc,,;:l:c,,;:oc;cdc,.;::dldoxd:ldol;,'..,:lo,,,,kOk
.......';'.',:clcll,,;:l:;'..''c:,;cl'.';dxoooxlddl;',''..,,;'...,ool
.......,,.'';;:cld;.;,do:..;:,':c',:c''';xxdldocol'..';,.......',;;,;
.......'..'',,coxc'';:do'.clc:lco',o;',;cOxdol:cc:.....'..oxd;','.'..
'.......''..,:cxl;';;cx:''cll:clc'cl',:l:ko:c..;c:..';...,KNNl;:;ll:'
.......''...;,ooc,,,:od'.':cccdd,,l''cl:co;;,..;;'..','..;d0O,;;:XXXK
............'cll;',,lo'.'.::codl,c..:c;doc.,:.',....'...'......'l0XKk
'............c;;,':lc.'',.;ccol;:,.:c.:o,;'.;'......,...',,.'...'.,;;
.............',;;,cc..;,'';:lc':;..c'.c:;.,......,'..'...'',:,,;;,...
..............',,;:'.';,',:c;.;;..';..,;,.........''..'...'kko.,,....
...............;,:'..;''';:,..;''.''..''............'...'.lK0c';;c;'.
...............,,'...,.',;''...''....,......'............'dOx',;:dd,'
..............',.....'.,;..'..',..........'..............';:;',,ldo.'
.............'''.'.....,'..',','..'...''..'............'.......,dx'.'
.......................,...';,'..'.....,.'.............''.'......'..'
...........'......'...',..'';,'..'.....................',';,..'....'.
```
