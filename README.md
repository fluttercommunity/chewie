# chewie

The video player for Flutter with a heart of gold. 

The [`video_player`](https://pub.dartlang.org/packages/video_player) plugin provides low-level access to video playback. Chewie uses the `video_player` under the hood and wraps it in a friendly Material or Cupertino UI! 

## Demo

![Demo](https://github.com/brianegan/chewie/raw/master/assets/chewie_demo.gif)

## Installation

In your `pubspec.yaml` file within your Flutter Project: 

```yaml
dependencies:
  chewie: <latest_version>
  video_player: <latest_version>
```

## Use it

```dart
import 'package:chewie/chewie.dart';
final videoPlayerController = VideoPlayerController.network(
    'https://flutter.github.io/assets-for-api-docs/videos/butterfly.mp4');

final chewieController = ChewieController(
  videoPlayerController: videoPlayerController,
  aspectRatio: 3 / 2,
  autoPlay: true,
  looping: true,
);

final playerWidget = Chewie(
  controller: chewieController,
);
```

Please make sure to dispose both controller widgets after use. For example by overriding the dispose method of the a `StatefulWidget`:
```dart
@override
void dispose() {
  videoPlayerController.dispose();
  chewieController.dispose();
  super.dispose();
}
```

## Example

Please run the app in the [`example/`](https://github.com/brianegan/chewie/tree/master/example) folder to start playing!

## Migrating from Chewie < 0.9.0
Instead of passing the `VideoPlayerController` and your options to the `Chewie` widget you now pass them to the `ChewieController` and pass that latter to the `Chewie` widget.

```dart
final playerWidget = Chewie(
  videoPlayerController,
  aspectRatio: 3 / 2,
  autoPlay: true,
  looping: true,
);
```

becomes

```dart
final chewieController = ChewieController(
  videoPlayerController: videoPlayerController,
  aspectRatio: 3 / 2,
  autoPlay: true,
  looping: true,
);

final playerWidget = Chewie(
  controller: chewieController,
);
```

## iOS warning

The video player plugin used by chewie is not functional on iOS simulators. An iOS device must be used during development/testing. Please refer to this [issue](https://github.com/flutter/flutter/issues/14647).


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
