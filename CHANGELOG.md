## 0.12.1+1

* Lint: Format to line length 80 for pub score

## 0.12.2

* Fix: Deprecation of [`resizeToAvoidBottomPadding`](https://api.flutter.dev/flutter/material/Scaffold/resizeToAvoidBottomPadding.html). Replaced by `resizeToAvoidBottomInset`
  - Thanks to: [#423](https://github.com/brianegan/chewie/pull/423)

## 0.12.1

* Fix: Duration called on null for cupertino controls
  - Thanks to: [#406](https://github.com/brianegan/chewie/pull/406)
* Bump required Flutter version 1.20 -> 1.22
  - Thanks to: [#401](https://github.com/brianegan/chewie/pull/401)
* Export controls in chewie.dart.
  - Thanks to: [#355](https://github.com/brianegan/chewie/pull/355)
* Add `lint` linter
* Add CI to analyze and check format

## 0.12.0

* Add replay feature
* Add Animated Play/Pause Button
  - Thanks to: [#228](https://github.com/brianegan/chewie/pull/228)

## 0.11.0

* Add playback speed controls:
  - Thanks to: [#390](https://github.com/brianegan/chewie/pull/390)
* Correct dependencies:
  - Thanks to: [#395](https://github.com/brianegan/chewie/pull/395)

## 0.10.4

* Update Android example to latest support
* Update Dart SDK
* Update Flutter SDK
* Update `wakelock` dependency

## 0.10.3+1

* Format using `dartfmt -w .` for pub.dev

## 0.10.3

* Bugfix: only `setState` if widget is mounted (cupertino + material)
  - Thanks to: [#309](https://github.com/brianegan/chewie/pull/309)

## 0.10.2

* Replace `open_iconic_flutter` with `cupertino_icons` to resolve Apple App-Store rejection (ITMS-90853)
  - Fixes: [#381](https://github.com/brianegan/chewie/issues/381)

## 0.10.1

* Update `video_player` dependecy (stable release)

## 0.10.0

  * Fix portrait mode
  * Add auto-detect orientation based on video aspect-ratio
  * Add optional parameters for `onEnterFullScreen`
  * Support iOS 14 with SafeArea in FullScreen

## 0.9.10

* Remove `isInitialRoute` from full screen page route

## 0.9.9

* Changed wakelock plugin from `flutter_screen` to `wakelock` due to lack of maintenance of `flutter_screen`. 

## 0.9.8+1
  * Require latest flutter stable version

## 0.9.8

  * Hero Widget is no longer used (thanks @localpcguy)
  * Tap to hide controls (thanks @bostrot)
  * Replay on play when video is finished (thanks @VictorUvarov)

## 0.9.7

  * Errors are properly handled. You can provide the Widget to display when an error occurs by providing an `errorBuilder` function to the `ChewieController` constructor.
  * Add ability to override the fullscreen page builder. Allows folks to customize that functionality!

## 0.9.6

  * Update to work with `video_player: ">=0.7.0 <0.11.0"`

## 0.9.5

  * Cosmetic change -> remove unfinished fit property which slipped into the last release

## 0.9.4

  * Add overlay option to place a widget between the video and the controls
  * Update to work with `video_player: ">=0.7.0 <0.10.0"`

## 0.9.3

  * Absorb pointer when controls are hidden

## 0.9.2

  * Add options to define system overlays after exiting full screen
  * Add option to hide mute button

## 0.9.1

  * Add option to hide full screen button

## 0.9.0

  * **Breaking changes**: Add a `ChewieController` to make customizations and control from outside of the player easier.
    Refer to the [README](README.md) for details on how to upgrade from previous versions.

## 0.8.0

  * Update to work with `video_player: ">=0.7.0 <0.8.0` - Thanks @Sub6Resources
  * Preserves AspectRatio on FullScreen - Thanks @patrickb
  * Ability to start video in FullScreen - Thanks @miguelpruivo

## 0.7.0

  * Requires Dart 2
  * Updated dependencies that were not Dart 2 compatible

## 0.6.1

  * Fix time formatting
  * Fix skipping
  * Remove listener when disposed
  * Start video at certain position

## 0.6.0

  * Update to work with `video_player: ">=0.6.0 <0.7.0`

## 0.5.1

  * Update README to fix installation instructions

## 0.5.0

  * Update to work with `video_player: ">=0.5.0 <0.6.0`

## 0.3.0

  * Update to work with `video_player: ">=0.2.0 <0.3.0`
  * Add `showControls` option. You can use this to show / hide the controls
  * Move from `VideoProgressColors` to `ChewieProgressColors` for customization of the Chewie progress controls
  * Remove `progressColors` in favor of platform-specific customizations: `cupertinoProgressColors` and `materialProgressColors` to control
  * Add analysis options

## 0.2.0

  * Take a `controller` instead of a `String uri`. Allows for better control of playback outside the player if need be.

## 0.1.1

  * Fix images in docs for pub

## 0.1.0

Initial version of Chewie, the video player with a heart of gold.

  * Hand a VideoPlayerController to Chewie, and let it do the rest.
  * Includes Material Player Controls
  * Includes Cupertino Player Controls
  * Spike version: Focus on good looking UI. Internal code is sloppy, needs a refactor and tests
