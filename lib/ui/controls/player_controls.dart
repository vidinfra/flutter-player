import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:goplayer/goplayer.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_preview_thumbnails/video_preview_thumbnails.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  PlayerState state(BuildContext context) => context.read<PlayerState>();

  ControlsConfiguration conf(BuildContext context) =>
      state(context).configuration;

  VideoPlayerController controller(BuildContext context) =>
      state(context).controller!;

  VideoPlayerValue player(BuildContext context) => state(context).player!;

  bool isFullScreen(BuildContext context) =>
      false; // controller(context).isFullScreen;

  @override
  Widget build(BuildContext context) {
    final GestureHandler gestureHandler = GestureHandler(context);

    return Consumer<PlayerState>(
      builder: (context, state, child) {
        if (state.nowPlaying == null) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              AnimatedOpacity(
                duration: Durations.medium3,
                opacity: state.controlsVisible ? 1 : 0,
                child: backgroundGradient(context),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: state.toggleControls,
                  onDoubleTapDown: gestureHandler.onDoubleTapDown,
                  onVerticalDragUpdate: gestureHandler.onVerticalDragUpdate,
                  onHorizontalDragUpdate: (details) {
                    // Prevents onVerticalDragUpdate being called
                  },
                ),
              ),
              Positioned.fill(child: controlsView(context, state)),
              if (state.controlsVisible &&
                  !state.locked &&
                  !state.loading &&
                  !state.userIsSeeking)
                Align(
                  alignment: Alignment.center,
                  child: playPauseButton(context),
                ),
              ...gestureStackViews(context, state),
              ...extraStackButtons(context, state),
              if (state.chipMessage != null)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: MessageChip(message: state.chipMessage!),
                )
            ],
          ),
        );
      },
    );
  }

  Widget backgroundGradient(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }

  Widget controlsView(BuildContext context, PlayerState state) {
    if (!state.controlsVisible) return const SizedBox.shrink();
    // double padding = state.controller.isFullScreen ? 12 : 0;

    return SafeArea(
      // top: state.controller.isFullScreen,
      // bottom: state.controller.isFullScreen,
      // left: state.controller.isFullScreen,
      // right: state.controller.isFullScreen,
      child: Padding(
        padding: EdgeInsets.all(0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.locked)
              ...lockScreenUI(context)
            // else if (controller(context).isLiveStream())
            //   ...liveStreamUI(context)
            else
              ...normalUI(context),
          ],
        ),
      ),
    );
  }

  List<Widget> gestureStackViews(BuildContext context, PlayerState state) {
    double volBrightValue = 0.0;
    Widget? volBrightIcon;
    if (state.brightnessGestureApplied) {
      volBrightIcon = SvgPicture.asset(conf(context).assetHelper.brightness);
      volBrightValue = state.brightness;
    } else if (state.volumeGestureApplied) {
      volBrightValue = state.volume;
      String icon = conf(context).assetHelper.volumeHigh;

      if (volBrightValue == 0.0) {
        // Asset jumps
        icon = conf(context).assetHelper.volumeMute;
      } else if (volBrightValue < 0.5) {
        icon = conf(context).assetHelper.volumeLow;
      }

      volBrightIcon = SvgPicture.asset(icon, height: 16, width: 16);
    }

    return [
      if (state.forwardGestureApplied || state.backwardGestureApplied) ...{
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: Colors.black38,
              child: Lottie.asset(
                fit: BoxFit.contain,
                alignment: state.forwardGestureApplied
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                state.forwardGestureApplied
                    ? conf(context).assetHelper.lottieForward
                    : conf(context).assetHelper.lottieBackward,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 28),
            child: progressTextView(context),
          ),
        ),
      },
      if (state.volumeGestureApplied || state.brightnessGestureApplied)
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Container(
              width: MediaQuery.of(context).size.width / 3,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(154),
                borderRadius: BorderRadius.circular(48),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: Row(
                children: [
                  if (volBrightIcon != null) volBrightIcon,
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: volBrightValue,
                      borderRadius: BorderRadius.circular(69),
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> extraStackButtons(BuildContext context, PlayerState state) {
    // if (!controller(context).isFullScreen || state.isInPip) return [];

    Media? nextMedia;
    if (state.canSkipToNextEpisode) {
      nextMedia = state.playlist[state.nowPlayingIndexInPlaylist! + 1];
    }

// TODO Inherit
    final buttonStyle = FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      textStyle: const TextStyle(color: Colors.white),
    );

    return [
      if (false && !state.userIsSeeking) ...{
        if (state.introSkippable)
          Positioned(
            left: 28,
            bottom: 90,
            child: FilledButton(
              style: buttonStyle,
              onPressed: state.skipIntro,
              child: const Text("Skip Intro",
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        if (nextMedia != null)
          Positioned(
            right: 28,
            bottom: 90,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.willSkipCredit)
                  FilledButton(
                    style: buttonStyle,
                    onPressed: state.dontSkipCredit,
                    child: const Text("Watch Credits"),
                  ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 222,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    minTileHeight: 48,
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onTap: state.skipToNextEpisode,
                    minLeadingWidth: 0,
                    leading: nextMedia.poster == null
                        ? null
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              height: 32,
                              imageUrl: nextMedia.poster!,
                            ),
                          ),
                    titleTextStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                    subtitleTextStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    subtitle: Text(nextMedia.title),
                    title: Text(
                      state.nextEpisodeAutoStartTime != null &&
                              !state.nextEpisodeAutoStartTime!.isNegative
                          ? "Next episode in ${state.nextEpisodeAutoStartTime!.inSeconds}s"
                          : "Next Episode",
                    ),
                  ),
                ),
              ],
            ),
          )
      },
    ];
  }

  Widget titleBar(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 6),
        IconButton(
          onPressed: conf(context).onBackPress ??
              () {
                if (isFullScreen(context)) {
                  //controller(context).exitFullScreen();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.pop(context);
                }
              },
          icon: SvgPicture.asset(conf(context).assetHelper.backButton),
        ),
        if (isFullScreen(context)) Text(state(context).nowPlaying!.title),
        const Spacer(),
        if (conf(context).pip)
          IconButton(
            constraints: const BoxConstraints(),
            icon: SvgPicture.asset(conf(context).assetHelper.pip),
            onPressed: conf(context).onPipClick ?? state(context).launchPip,
          ),
        if (conf(context).cast)
          IconButton(
            constraints: const BoxConstraints(),
            onPressed: conf(context).onCastClick ??
                () => state(context).launchCast(context),
            icon: SvgPicture.asset(conf(context).assetHelper.screenCast),
          ),
        IconButton(
          constraints: const BoxConstraints(),
          onPressed: () => SettingsMenu.show(context),
          icon: SvgPicture.asset(conf(context).assetHelper.settings),
        )
      ],
    );
  }

  Widget playPauseButton(BuildContext context) {
    if (player(context).isPlaying) {
      return IconButton(
        onPressed: () {
          controller(context).pause();
          state(context).restartControlsHideTimer();
        },
        icon: SvgPicture.asset(conf(context).assetHelper.pause),
      );
    }
    return IconButton(
      onPressed: () {
        controller(context).play();
        state(context).restartControlsHideTimer();
      },
      icon: SvgPicture.asset(conf(context).assetHelper.play),
    );
  }

  Widget bottomActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(width: 6),
            IconButton(
              constraints: const BoxConstraints(),
              onPressed: () => state(context).toggleLock(),
              icon: SvgPicture.asset(conf(context).assetHelper.lock),
            ),
            //if (controller(context).isLiveStream()) liveIndicator(context),
            const Spacer(),
            if (isFullScreen(context) && false
                // !controller(context).isLiveStream()
                ) ...{
              if (conf(context).onEpisodesClick != null)
                TextButton.icon(
                  onPressed: conf(context).onEpisodesClick,
                  label: const Text(
                    "Episodes",
                    style: TextStyle(color: Colors.white),
                  ),
                  icon: SvgPicture.asset(conf(context).assetHelper.episodes),
                ),
              if (conf(context).onNextEpisodeClick != null)
                TextButton.icon(
                  onPressed: conf(context).onNextEpisodeClick,
                  label: const Text(
                    "Next Episode",
                    style: TextStyle(color: Colors.white),
                  ),
                  icon: SvgPicture.asset(conf(context).assetHelper.nextEpisode),
                ),
              const Spacer(),
            },
            if (isFullScreen(context))
              IconButton(
                constraints: const BoxConstraints(),
                onPressed: () => state(context).toggleFit(),
                icon: SvgPicture.asset(
                  state(context).isExpandedFit
                      ? conf(context).assetHelper.fitContain
                      : conf(context).assetHelper.fitCover,
                ),
              ),
            if (conf(context).rotate)
              IconButton(
                constraints: const BoxConstraints(),
                onPressed: () {
                  if (isFullScreen(context)) {
                    //controller(context).exitFullScreen();
                  } else {
                    //controller(context).enterFullScreen();
                  }
                },
                icon: SvgPicture.asset(
                  conf(context).assetHelper.rotate,
                ),
              ),
            const SizedBox(width: 6),
          ],
        ),
      ],
    );
  }

  List<Widget> lockScreenUI(BuildContext context) {
    return [
      Expanded(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 200,
              child: ListTile(
                autofocus: true,
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                tileColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(48),
                ),
                onTap: state(context).toggleLock,
                title: const Text("Screen Locked"),
                subtitle: const Text("Tap To Unlock"),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: SvgPicture.asset(
                    conf(context).assetHelper.unlock,
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      )
    ];
  }

  Widget liveIndicator(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.red,
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          "Live",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget progressTextView(BuildContext context) {
    //if (controller(context).isLiveStream()) return const SizedBox.shrink();
    if (state(context).duration == null) return const SizedBox.shrink();
    if (state(context).progress == null) return const SizedBox.shrink();

    return Text(
      "${state(context).progress.formatHHMMSS()}"
      "/${state(context).duration.formatHHMMSS()}",
      maxLines: 1,
    );
  }

  List<Widget> liveStreamUI(BuildContext context) {
    return [
      titleBar(context),
      const Spacer(),
      bottomActions(context),
    ];
  }

  List<Widget> normalUI(BuildContext context) {
    return [
      titleBar(context),
      Expanded(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  const Expanded(child: SeekBar()),
                  progressTextView(context),
                  if (!isFullScreen(context) && conf(context).rotate)
                    IconButton(
                      onPressed: () {
                        // controller(context).enterFullScreen();
                      },
                      icon: SvgPicture.asset(conf(context).assetHelper.rotate),
                    )
                  else
                    const SizedBox(width: 12)
                ],
              ),
            ),
            if (_shouldShowThumbnail(context)) thumbBuilder(context),
          ],
        ),
      ),
      if (isFullScreen(context)) bottomActions(context),
    ];
  }

  double _thumbSlidePosition(
    BuildContext context,
    VideoPreviewThumbnailsValue value,
  ) {
    double width = MediaQuery.of(context).size.width - 150;

    final percentage = width / state(context).duration!.inMilliseconds;
    final left = percentage * value.currentTimeMilliseconds;

    return (left - (156 / 2)).clamp(8, width - 156);
  }

  bool _shouldShowThumbnail(BuildContext context) {
    return state(context).userIsSeeking &&
        state(context).thumbnailVTT != null &&
        state(context).thumbnailSprite != null;
  }

  Widget thumbBuilder(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: state(context).thumbnailController,
      builder: (context, value, child) => Positioned(
        bottom: 60,
        left: _thumbSlidePosition(context, value),
        child: Container(
          height: 87,
          width: 156,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              const BoxShadow(
                blurRadius: 4,
                offset: Offset(0, 4),
                color: Colors.black12,
              )
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: VideoPreviewThumbnails(
                  vtt: state(context).thumbnailVTT!,
                  controller: state(context).thumbnailController,
                  image: state(context).thumbnailSprite,
                  baseUrlVttImages: state(context).nowPlaying!.thumbVTTBaseUrl,
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      Duration(
                        milliseconds: value.currentTimeMilliseconds,
                      ).formatHHMMSS(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
