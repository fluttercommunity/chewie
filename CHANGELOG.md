## 1.3.4
* ⬆️ [#646](https://github.com/fluttercommunity/chewie/pull/646): Fix to videos recorded with an orientation of 180° ( landscapeRight) being reversed on Android. Thanks [williamviktorsson](https://github.com/williamviktorsson).
* ⬆️ [#623](https://github.com/fluttercommunity/chewie/pull/646): [Android] Add a delay before displaying progress indicator. Thanks [henri2h](https://github.com/henri2h).

## 1.3.3
* ⬆️ [#634](https://github.com/fluttercommunity/chewie/pull/634): chore: Move very_good_analysis to dev_dependencies. Thanks [JCQuintas](https://github.com/JCQuintas).

## 1.3.2
* ⬆️ [#626](https://github.com/fluttercommunity/chewie/pull/626): Added customizable timer to hide controls. Thanks [BuginRug](https://github.com/BuginRug).

## 1.3.1
* ⬆️ [#617](https://github.com/fluttercommunity/chewie/pull/617): Allow video zooming with InteractiveViewer widget. Thanks [jmsanc](https://github.com/jmsanc).

## 1.3.0

* ⬆️ [#598](https://github.com/fluttercommunity/chewie/pull/598): Update `wakelock` to `^0.6.1+1`. Thanks [fehernyul](https://github.com/fehernyul).
* ⬆️ [#599](https://github.com/fluttercommunity/chewie/pull/599): Uniform controls. Thanks [BuginRug](https://github.com/BuginRug).

  **Slight Breaking Change**. Instead of:
  
  ```dart
  typedef ChewieRoutePageBuilder = Widget Function(
  	  BuildContext context,
  	  Animation<double> animation,
      Animation<double> secondaryAnimation,
      _ChewieControllerProvider controllerProvider,
  );
  ```
  
  It is now:
  
  ```dart
  typedef ChewieRoutePageBuilder = Widget Function(
  	  BuildContext context,
  	  Animation<double> animation,
      Animation<double> secondaryAnimation,
      ChewieControllerProvider controllerProvider,
  );
  ```
  
  TL;DR: We had to make `_ChewieControllerProvider` public.
  
* 🛠️ Fixed lint and formatting problems
* Under New Management under the auspices of [Flutter Community](https://github.com/fluttercommunity), and new maintainers [diegotori](https://github.com/diegotori) and [maherjaafar](https://github.com/maherjaafar).

## 1.2.3

* ⬆️ Update 'provider' to 6.0.1
  - fixes [#568](https://github.com/brianegan/chewie/issues/568)
* ⬆️ Update 'video_player' to 2.2.7
* ⬆️ Update 'wakelock' to 0.5.6
* ⬆️ Update 'lint' to 1.7.2
* ⬆️ Update roadmap
* 🛠️ Fix lint problems
* 💡 Add very_good_analysis package
* 💡 Add analysis_options.yaml for example app

## 1.2.2

* 🛠️ Fix Incorrect use of ParentDataWidget.
  - Fixes: [#485](https://github.com/brianegan/chewie/issues/485)

## 1.2.1

* 💡 add `showOptions` flag to show/hide the options-menu
  - Fixes: [#491](https://github.com/brianegan/chewie/issues/491)
* ⬆️ update `video_player` to 2.1.5
* 🛠️ fix MaterialUI duration text (RichText)

## 1.2.0

* 🖥 __Desktop-UI__: Added `AdaptiveControls` where `MaterialDesktopControls` is now the default for Desktop-Platforms (start [ChewieDemo](https://github.com/brianegan/chewie/blob/master/example/lib/app/app.dart) for a preview)
  - Fixes: [#188](https://github.com/brianegan/chewie/issues/478)
* Redesign `MaterialControls` (inspired by Youtube Mobile and Desktop)
* Fix squeeze of `CenterPlayButton`
* Add: `optionsTranslation`, `additionalOptions` and `optionsBuilder` to create and design your Video-Options like Playback speed, subtitles and other options you want to add (use here: `additionalOptions`!). Use `optionsTranslation` to provide your localized strings!

> See [Options](https://github.com/brianegan/chewie#options) to customize your Chewie options

## 1.1.0

* Add subtitle functionality
  - Thanks to kirill09: [#188](https://github.com/brianegan/chewie/pull/188) with which we've improved and optimized subtitles

> See readme on how to create subtitles and provide your own subtitleBuilder: [Subtitles](https://github.com/brianegan/chewie#Subtitles)

## 1.0.0

* Migrate to Null Safety
  - Thanks to miDeb: [#406](https://github.com/brianegan/chewie/pull/443)

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

