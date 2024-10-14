import 'package:easy_localization/easy_localization.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../../../chewie.dart';
import '../../../chewie_player.dart';
import '../../../config/icons.dart';
import '../../../gen/locale_keys.g.dart';
import '../../../helpers/models/audio_track.dart';
import '../../../helpers/models/video_track.dart';
import '../../../player_with_controls.dart';
import '../../../widgets/sheet/player_bottom_sheet.dart';
import '../../widgets/buttons/player_tile_button.dart';
import 'generic_simple_choose_sheet.dart';

Future<void> showPlayerSettings(
  BuildContext context, {
  required ChewieController controller,
}) async {
  return showPlayerBottomSheet(
    context,
    child: SettingsView(
      controller: controller,
    ),
  );
}

class SettingsView extends StatefulWidget {
  const SettingsView({
    required this.controller,
    super.key,
  });

  final ChewieController controller;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _pageController = PageController();
  var _selectedPage = 0;
  var _isScrolled = false;
  late final _videoController = widget.controller.videoPlayerController;

  void _animateTo(int index) {
    _pageController.animateToPage(
      index,
      duration: 300.ms,
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      SettingsMainView(
        controller: widget.controller,
        onPageChange: (page) {
          setState(() {
            _selectedPage = page;
          });
          _animateTo(1);
        },
      ),
      [
        GenericSimpleChooseSheet<VideoTrack>(
          onPressBack: () => _animateTo(0),
          title: LocaleKeys.player_settings_quality.tr(),
          items: widget.controller.videoTracks,
          onItemTap: (track) {
            widget.controller.setVideoTrack(track);
            setState(() {});
            Navigator.pop(context);
          },
          selectedItem: widget.controller.videoTrack,
          buildItemLabel: (item) {
            return item.name ?? item.resolution?.split('x').last ?? 'Unknown';
          },
        ),
        if (widget.controller.audioTracks.isNotEmpty)
          GenericSimpleChooseSheet<AudioTrack>(
            onPressBack: () => _animateTo(0),
            title: LocaleKeys.player_settings_lang.tr(),
            items: widget.controller.audioTracks.where(
              (item) {
                if (item.groupId == null) {
                  return true;
                }

                final track = widget.controller.videoTrack;

                if (track.isAuto) {
                  return item.groupId ==
                      widget.controller.audioTracks.first.groupId;
                }

                return item.groupId == track.audioGroupId;
              },
            ).toList(),
            selectedItem: widget.controller.audioTrack,
            onItemTap: (track) {
              widget.controller.setAudioTrack(track);
              setState(() {});
              Navigator.pop(context);
            },
            buildItemLabel: (item) {
              return item.name ?? 'Unknown';
            },
          ),
        GenericSimpleChooseSheet<double>(
          onPressBack: () => _animateTo(0),
          items: widget.controller.playbackSpeeds,
          title: LocaleKeys.player_settings_speed.tr(),
          selectedItem: _videoController.value.playbackSpeed,
          onItemTap: (item) async {
            await widget.controller.videoPlayerController
                .setPlaybackSpeed(item);

            final pref = await SharedPreferences.getInstance();

            await pref.setDouble(speedKey, item);

            setState(() {});

            Navigator.pop(context);
          },
          buildItemLabel: (double item) {
            return item.toString();
          },
        ),
        // GenericSimpleChooseSheet<dynamic>(
        //   onPressBack: () => _animateTo(0),
        //   title: LocaleKeys.player_settings_subtitle.tr(),
        //   buildItemLabel: (item) {
        //     return '';
        //   },
        // ),
      ][_selectedPage],
    ];

    return ExpandablePageView.builder(
      animationCurve: Curves.ease,
      controller: _pageController,
      physics: _isScrolled ? const NeverScrollableScrollPhysics() : null,
      animationDuration: const Duration(milliseconds: 400),
      itemCount: pages.length,
      onPageChanged: (value) {
        setState(() {
          _isScrolled = value == 0;
        });
      },
      itemBuilder: (context, index) {
        return pages[index];
      },
    );
  }
}

class SettingsMainView extends StatelessWidget {
  SettingsMainView({
    required this.onPageChange,
    required this.controller,
    super.key,
  }) : _videoPlayerController = controller.videoPlayerController;

  final ChewieController controller;
  final void Function(int) onPageChange;

  final VideoPlayerController _videoPlayerController;

  @override
  Widget build(BuildContext context) {
    return PlayerBottomSheetWrap(
      title: LocaleKeys.player_settings_title.tr(),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerTileButton(
            onPressed: () => onPageChange(0),
            title: LocaleKeys.player_settings_quality.tr(),
            value: controller.videoTrack.name ??
                controller.videoTrack.resolution?.split('x').last ??
                'Unknown',
            icon: PlayerIcons.settings,
          ),
          if (controller.audioTracks.isNotEmpty)
            PlayerTileButton(
              onPressed: () => onPageChange(1),
              title: LocaleKeys.player_settings_lang.tr(),
              value: controller.audioTrack?.name ?? 'Default',
              icon: PlayerIcons.language,
            ),
          PlayerTileButton(
            onPressed: () => onPageChange(2),
            title: LocaleKeys.player_settings_speed.tr(),
            value: _videoPlayerController.value.playbackSpeed.toString(),
            icon: PlayerIcons.speed,
          ),
          // PlayerTileButton(
          //   onPressed: () => onPageChange(3),
          //   title: LocaleKeys.player_settings_subtitle.tr(),
          //   isShowDivider: false,
          //   value: '',
          //   icon: PlayerIcons.subtitle,
          // ),
        ],
      ),
    );
  }
}
