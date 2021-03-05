# chewie_audio
[![Version](https://img.shields.io/pub/v/chewie_audio.svg)](https://pub.dev/packages/chewie_audio)
![CI](https://github.com/Sub6Resources/chewie_audio/workflows/CI/badge.svg)
[![Generic badge](https://img.shields.io/badge/platform-android%20|%20ios%20|%20web%20-blue.svg)](https://pub.dev/packages/chewie_audio)


The audio player for Flutter with a heart of gold. 

The [`video_player`](https://pub.dartlang.org/packages/video_player) plugin provides low-level access to video/audio playback. Chewie Audio uses the `video_player` under the hood and wraps it in a friendly Material or Cupertino UI!

## Preview

| MaterialControls | MaterialDesktopControls |
| :--------------: | :---------------------: |
|     ![](https://github.com/brianegan/chewie/raw/master/assets/MaterialControls.png)     |    ![](https://github.com/brianegan/chewie/raw/master/assets/MaterialDesktopControls.png)     |

### CupertinoControls
![](https://github.com/brianegan/chewie/raw/master/assets/CupertinoControls.png)

## Installation

In your `pubspec.yaml` file within your Flutter Project: 

```yaml
dependencies:
  chewie_audio: <latest_version>
  video_player: <latest_version>
```

## Use it

```dart
import 'package:chewie_audio/chewie_audio.dart';
final videoPlayerController = VideoPlayerController.network(
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4');

await videoPlayerController.initialize();

final chewieAudioController = ChewieAudioController(
  videoPlayerController: videoPlayerController,
  autoPlay: true,
  looping: true,
);

final playerWidget = ChewieAudio(
  controller: chewieAudioController,
);
```

Please make sure to dispose both controller widgets after use. For example by overriding the dispose method of the a `StatefulWidget`:
```dart
@override
void dispose() {
  videoPlayerController.dispose();
  chewieAudioController.dispose();
  super.dispose();
}
```

## Options

![](https://github.com/brianegan/chewie/raw/master/assets/Options.png)

Chewie got some options which controls the video you provide. These options appear on default on a `showModalBottomSheet` (like you already know from YT maybe). Chewie is passing on default `Playback speed` and `Subtitles` options as an `OptionItem`.

To add additional options just add these lines to your `ChewieController`:

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
          debugPrint('Another option working!'),
      iconData: Icons.chat,
      title: 'Another localized title',
    ),
  ];
},
```

If you don't like to show your options with the default `showModalBottomSheet` just override the View with the `optionsBuilder` method:

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

Last but not least: What is an option without proper translation. To add your strings to them just add:

```dart
optionsTranslation: OptionsTranslation(
  playbackSpeedButtonText: 'Wiedergabegeschwindigkeit',
  subtitlesButtonText: 'Untertitel',
  cancelButtonText: 'Abbrechen',
),
```

## Subtitles

> Since version 1.1.0 chewie supports subtitles. Here you can see how to use them

You can provide an `List<Subtitle>` and customize your subtitles with the `subtitleBuilder` function.

Just add subtitles as following code is showing into your `ChewieController`:

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

The `index` attribute is just for purpases if you want to structure your subtitles in your database and provide your indexes here. `start`, `end` and `text` are here the key attributes. 

The Duration defines on which part of your video your subtitles should start and end. For example: Your video is 10 minutes long and you want to add a subtitle between: `00:00` and `00:10`'th second you've to provide:

```dart
Subtitle(
  index: 0,
  start: Duration.zero,
  end: const Duration(seconds: 10),
  text: 'Hello from subtitles',
),
```

## Example

Please run the app in the [`example/`](https://github.com/Sub6Resources/chewie_audio/tree/master/example) folder to start playing!

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
The video_player plugin used by chewie_audio will only work in iOS simulators if you are on Flutter 1.26.0+.
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
