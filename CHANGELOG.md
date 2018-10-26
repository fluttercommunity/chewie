# Changelog

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
