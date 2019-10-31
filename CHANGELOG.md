# Changelog

## 0.10.0

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
