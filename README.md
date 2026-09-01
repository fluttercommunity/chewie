# chewie

[![Flutter Community: chewie](https://fluttercommunity.dev/_github/header/chewie)](https://github.com/fluttercommunity/community)

[![Version](https://img.shields.io/pub/v/chewie.svg)](https://pub.dev/packages/chewie)
![CI](https://github.com/brianegan/chewie/workflows/CI/badge.svg)
[![Generic badge](https://img.shields.io/badge/platform-android%20|%20ios%20|%20web%20-blue.svg)](https://pub.dev/packages/chewie)

The video player for Flutter with a heart of gold. 

The [`video_player`](https://pub.dartlang.org/packages/video_player) plugin provides low-level 
access to video playback. 

Chewie uses the `video_player` under the hood and wraps it in a friendly Material or Cupertino UI!

## Table of Contents
1.  🚨 [IMPORTANT!!! (READ THIS FIRST)](#-important-read-this-first)
2.  🔀 [Flutter Version Compatibility](#-flutter-version-compatibility)
3.  🖼️ [Preview](#%EF%B8%8F-preview)
4.  ⬇️ [Installation](#%EF%B8%8F-installation)
5.  🕹️ [Using it](#%EF%B8%8F-using-it)
6.  ⚙️ [Options](#%EF%B8%8F-options)
7.  🔡 [Subtitles](#-subtitles)
8.  📺 [Casting](#-casting)
9.  🧪 [Example](#-example)
10. ⏪ [Migrating from Chewie < 0.9.0](#-migrating-from-chewie--090)
11. 🗺️ [Roadmap](#%EF%B8%8F-roadmap)
12. ⚠️ [Android warning](#%EF%B8%8F-android-warning)
13. 📱 [iOS warning](#-ios-warning)


## 🚨 IMPORTANT!!! (READ THIS FIRST)
This library is __NOT__ responsible for any issues caused by `video_player`, since it's merely a UI 
layer on top of it. 

In other words, if you see any `PlatformException`s being thrown in your app due to video playback,
they are exclusive to the `video_player` library. 

Instead, please raise an issue related to it with the [Flutter Team](https://github.com/flutter/flutter/issues/new/choose).

## 🔀 Flutter Version Compatibility

This library will at the very least make a solid effort to support the second most recent version 
of Flutter released. In other words, it will adopt `N-1` version support at
the bare minimum.

However, this cannot be guaranteed either due to major changes between Flutter versions or 
this library's dependencies. Should that occur, future updates will be released as major or minor 
versions as needed.

## 🖼️ Preview

|                                MaterialControls                                 |                                MaterialDesktopControls                                 |
|:-------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------:|
| ![](https://github.com/brianegan/chewie/raw/master/assets/MaterialControls.png) | ![](https://github.com/brianegan/chewie/raw/master/assets/MaterialDesktopControls.png) |

### CupertinoControls
![](https://github.com/brianegan/chewie/raw/master/assets/CupertinoControls.png)

## ⬇️ Installation

In your `pubspec.yaml` file within your Flutter Project add `chewie` and `video_player` under dependencies:

```yaml
dependencies:
  chewie: <latest_version>
  video_player: <latest_version>
```

## 🕹️ Using it

```dart
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

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

## ⚙️ Options

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

## 🔡 Subtitles

> Since version 1.1.0, Chewie supports subtitles.

Chewie allows you to enhance the video playback experience with text overlays. You can add a `List<Subtitle>` to your `ChewieController`, restyle the default subtitle box with `subtitleStyle`, or replace it entirely with the `subtitleBuilder` function.

### Showing Subtitles by Default

Chewie provides the `showSubtitles` flag, allowing you to control whether subtitles are displayed automatically when the video starts. By default, this flag is set to `false`.

### Adding Subtitles

Here’s an example of how to add subtitles to your `ChewieController`:

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
      text: 'What’s up? :)',
    ),
  ]),
  showSubtitles: true, // Automatically display subtitles
  subtitleBuilder: (context, subtitle) => Container(
    padding: const EdgeInsets.all(10.0),
    child: Text(
      subtitle,
      style: const TextStyle(color: Colors.white),
    ),
  ),
);
```

### Subtitle Structure

The `Subtitle` model contains the following key attributes:

- **`index`**: A unique identifier for the subtitle, useful for database integration.
- **`start`**: The starting point of the subtitle, defined as a `Duration`.
- **`end`**: The ending point of the subtitle, defined as a `Duration`.
- **`text`**: The subtitle text that will be displayed.

For example, if your video is 10 minutes long and you want to add a subtitle that appears between `00:00` and `00:10`, you can define it like this:

```dart
Subtitle(
  index: 0,
  start: Duration.zero,
  end: const Duration(seconds: 10),
  text: 'Hello from subtitles',
),
```

### Markup in Subtitle Text

Cue text extracted from WebVTT or SubRip files often carries inline markup, and Chewie renders it for you:

```dart
Subtitle(
  index: 0,
  start: Duration.zero,
  end: const Duration(seconds: 10),
  text: '<i>The law is the law, Mr. Hancock.</i>',
),
```

`<b>`, `<i>`, `<u>` and `<font color="#rrggbb">` are applied on top of your text style. The other WebVTT cue tags — `<c.class>`, `<v Speaker>`, `<lang xx>`, `<ruby>`/`<rt>` and timestamp tags — are dropped while their text is kept, and escapes such as `&amp;` are decoded. A tag that opens on one line and closes on the next works too.

Parsing is lenient, so cue text is never mangled: `5 < 10` and `<3` are shown as written, an unclosed tag simply runs to the end of the cue, and a stray closing tag is ignored. If you would rather show cue text exactly as it arrives, set `subtitleStyle: SubtitleStyle(renderMarkup: false)`.

### Styling Subtitles

`subtitleStyle` changes how the default subtitle box looks without giving up markup rendering:

```dart
ChewieController(
  videoPlayerController: _videoPlayerController,
  subtitleStyle: const SubtitleStyle(
    textStyle: TextStyle(fontSize: 22, color: Colors.amber),
    textAlign: TextAlign.center,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.black54),
  ),
);
```

Leaving `textStyle.color` unset inherits the colour from the surrounding `DefaultTextStyle`, which is what Chewie does by default.

### Customizing Subtitles

Reach for `subtitleBuilder` when you need to build the whole widget yourself. It receives the cue exactly as you supplied it — markup and all — and Chewie's own rendering, including `subtitleStyle`, is skipped. Run the cue through `parseSubtitleMarkup` to keep markup working:

```dart
subtitleBuilder: (context, subtitle) => Container(
  padding: const EdgeInsets.all(10.0),
  child: Text.rich(
    subtitle is String
        ? parseSubtitleMarkup(
            subtitle,
            style: const TextStyle(color: Colors.white),
          )
        : TextSpan(text: subtitle.toString()),
  ),
),
```

## 📺 Casting

Chewie can hand playback over to a cast receiver — a Chromecast, an Android TV,
anything you can talk to — and drive it from the same controls.

What Chewie provides is the UI and the handover: a cast button in every skin, a
device picker, an overlay in place of the video while a session is live, and the
local↔remote transitions in both directions. What it deliberately does **not**
provide is a sender. A pure-Flutter video player package has no business
dragging the Google Cast SDK, its native dependencies and its permission
requirements into every app that just wants play controls — so you supply the
backend, and Chewie stays agnostic about which one.

### Wiring it up

Implement `ChewieCastController` against the sender of your choice, then hand it
to the `ChewieController` along with the media the receiver should fetch:

```dart
final castController = MyCastController(); // your ChewieCastController

_chewieController = ChewieController(
  videoPlayerController: _videoPlayerController,
  castController: castController,
  castMedia: const CastMedia(
    url: 'https://example.com/video.mp4',
    mimeType: 'video/mp4',
    title: 'Big Buck Bunny',
  ),
);
```

`castMedia` is required whenever `castController` is set. Chewie cannot derive
it from the `VideoPlayerController`: the receiver fetches the stream itself, so
the URL has to be reachable **from the TV**, and a `file://` or asset source has
no remote equivalent at all.

### What happens on connect

When your controller moves its `connectionState` to
`CastConnectionState.connected`, Chewie:

1. pauses the local player and notes where it was,
2. calls `load(castMedia, startAt: <that position>, autoPlay: <was it playing>)`,
3. replaces the video surface with the casting overlay,
4. routes play, pause, seek, volume and the progress bar to the receiver.

On `disconnected` it runs the same trip in reverse, seeking the local player to
wherever the receiver got to and resuming if it was playing. Chewie listens to
your controller but never disposes it, so one instance can serve many videos.

### Implementing a backend

`ChewieCastController` is a `ChangeNotifier` with three groups of members:
discovery (`devices`, `isDiscovering`, `startDiscovery`, `stopDiscovery`),
session (`connectionState`, `connectedDevice`, `connect`, `disconnect`) and
remote playback (`value`, `load`, `play`, `pause`, `seekTo`, `setVolume`,
`setPlaybackSpeed`). Call `notifyListeners()` whenever any of them change —
every piece of cast UI rebuilds off those notifications.

`value` is a `VideoPlayerValue`, the same type the local player reports, which is
what lets one set of controls render a remote session identically to a local
one. Only `duration`, `position`, `buffered`, `isPlaying`, `isBuffering`,
`isInitialized`, `volume` and `playbackSpeed` are read; leave the rest at their
defaults.

The example app ships a `DemoCastController` that fakes discovery, a connection
delay and a ticking receiver, so you can see the whole flow without a
Chromecast on the desk.

### Options

| Option | Description |
| --- | --- |
| `castController` | Your backend. Casting is off entirely when this is null. |
| `castMedia` | What the receiver should play. Required alongside `castController`. |
| `allowCasting` | Hides the cast button without tearing the backend out. Defaults to `true`. |
| `castTranslations` | Strings for the button, picker and overlay. |
| `castOverlayBuilder` | Replaces the default "Casting to …" overlay. |
| `additionalControls` | Extra widgets for the control bar itself, for controls that cannot be an options-sheet row. |

### Extra control-bar buttons

`additionalOptions` adds rows to the options sheet. When a control has to be a
*widget* rather than a menu entry — a platform view, say — put it in the bar
itself:

```dart
ChewieController(
  videoPlayerController: videoPlayerController,
  additionalControls: (context) => const [AirPlayButton()],
);
```

They sit alongside the built-in buttons and inherit the bar's show/hide
behaviour, so they fade with the rest of the controls instead of floating over
the video.

The motivating case is AirPlay: Apple exposes no way to select a route
programmatically, so the button must be UIKit's own `AVRoutePickerView`.

## 🧪 Example

Please run the app in the [`example/`](https://github.com/brianegan/chewie/tree/master/example) folder to start playing!

## ⏪ Migrating from Chewie < 0.9.0

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

## 🗺️ Roadmap

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
- [x] Screen-Mirroring / Casting (backend-agnostic; see [Casting](#-casting))


## ⚠️ Android warning

There is an open [issue](https://github.com/flutter/flutter/issues/165149) that the buffering state of a video is not reported correctly. With this, the loading state is always triggered, hiding controls to play, pause or seek the video. A workaround was implemented until this is fixed, however it can't be perfect and still hides controls if seeking backwards while the video is paused, as a result of lack of correct buffering information (see #912).

Add the following to partly fix this behavior:

```dart
  // Your init code can be above
  videoController.addListener(yourListeningMethod);

  // ...

  bool wasPlayingBefore = false;
  void yourListeningMethod() {
    if (!videoController.value.isPlaying && !wasPlayingBefore) {
      // -> Workaround if seekTo another position while it was paused before.
      //    On Android this might lead to infinite loading, so just play the
      //    video again.
      videoController.play();
    }

    wasPlayingBefore = videoController.value.isPlaying;

  // ...
  }
```

You can also disable the loading spinner entirely to fix this problem in a more _complete_ way, however will remove the loading indicator if a video is buffering.

```dart
_chewieController = ChewieController(
  videoPlayerController: _videoPlayerController,
  progressIndicatorDelay: Platform.isAndroid ? const Duration(days: 1) : null,
);
```

## 📱 iOS warning 

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
