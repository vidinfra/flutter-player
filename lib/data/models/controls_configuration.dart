import 'package:flutter/material.dart';
import 'package:goplayer/goplayer.dart';

class ControlsConfiguration {
  // Modify assets by overrinding this class
  PlayerAssetHelper assetHelper = PlayerAssetHelper();

  bool pip, cast, rotate;
  Duration autoHideDuration;

  VoidCallback? onNextEpisodeClick, onEpisodesClick;

  /// Override default behaviour
  VoidCallback? onPipClick, onCastClick;

  /// Override default behaviour
  VoidCallback? onBackPress;

  /// Override default behaviour
  // VoidCallback? onSkipIntro, onCastClick;

  /// Callback that fires after now playing media [and post clip] has finished;
  /// Also fires if the media is skipped via [Next Episode] button
  VoidCallback? onMediaEnd;

  Duration seekGestureDuration, creditSkipConfirmDuration;

  ControlsConfiguration({
    this.pip = true,
    this.cast = true,
    this.rotate = true,
    this.autoHideDuration = const Duration(seconds: 5),
    this.seekGestureDuration = const Duration(seconds: 10),
    this.creditSkipConfirmDuration = const Duration(seconds: 10),
  });
}
