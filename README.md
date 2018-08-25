# custom_chewie


## fork
A custom [chewie](https://github.com/brianegan/chewie) fork that has a unique design and some extra features.

The video player for Flutter with a heart of gold. 

The [`video_player`](https://pub.dartlang.org/packages/video_player) plugin provides low-level access to video playback. Chewie uses the `video_player` under the hood and wraps it in a friendly Material or Cupertino UI! 

### features
* Fullscreen on orientation change to landscape
* Exit fullscreen on portrait orientation
* Picture in Picture for Android SDK > 24
* Custom design
* Back button


## Demo

<img src="https://github.com/bostrot/chewie/raw/master/assets/chewie_demo.gif" width="300" />

## Installation

In your `pubspec.yaml` file within your Flutter Project: 

```yaml
dependencies:
  custom_chewie: <latest_version>
```

## Use it

```dart
import 'package:custom_chewie/custom_chewie.dart';

final playerWidget = new Chewie(
  new VideoPlayerController.network(
    'https://flutter.github.io/assets-for-api-docs/videos/butterfly.mp4'
  ),
  aspectRatio: 3 / 2,
  autoPlay: true,
  looping: true,
);
```

## Example

Please run the app in the [`example/`](https://github.com/bostrot/chewie/tree/master/example) folder to start playing!
