import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:goplayer/goplayer.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({super.key});

  static Future<T?> show<T>(BuildContext context, {Widget? menu}) async {
    return await showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 400),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xff27272a),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ChangeNotifierProvider.value(
              value: context.read<PlayerState>(),
              child: menu ?? const SettingsMenu(),
            ),
          ),
        ),
      ),
    );
  }

  final listTileTheme = const ListTileThemeData(
    dense: true,
    horizontalTitleGap: 18,
    minLeadingWidth: 0,
    minVerticalPadding: 0,
    leadingAndTrailingTextStyle: TextStyle(color: Colors.white60),
  );

  PlayerState state(BuildContext context) => context.read<PlayerState>();

  ControlsConfiguration conf(BuildContext context) =>
      state(context).configuration;

  VideoPlayerController controller(BuildContext context) =>
      state(context).controller!;

  @override
  Widget build(BuildContext context) {
    final speed = context.read<PlayerState>().speed;
    final sub = state(context).player!.caption;

    // final audio = controller(context).betterPlayerAsmsAudioTrack ??
    //     controller(context).betterPlayerAsmsAudioTracks?.firstOrNull;

    // final subName =
    //     sub?.type == BetterPlayerSubtitlesSourceType.none ? "Off" : sub?.name;

    // final track = controller(context).betterPlayerAsmsTrack ??
    //     BetterPlayerAsmsTrack.defaultTrack();

    return ListTileTheme(
      data: listTileTheme,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: DragHandle()),
            //
            // ListTile(
            //   leading: SvgPicture.asset(conf(context).assetHelper.quality),
            //   title: const Text("Quality"),
            //   trailing: Text(track.width == 0 ? "Auto" : "${track.height}p"),
            //   onTap: () => show<BetterPlayerAsmsTrack>(
            //     context,
            //     menu: qualityPickerMenu(context),
            //   ).then((value) {
            //     if (value == null || !context.mounted) return;
            //     controller(context).setTrack(value);
            //     Navigator.pop(context);
            //   }),
            // ),
            //

            // ListTile(
            //   leading: SvgPicture.asset(conf(context).assetHelper.subtitle),
            //   title: const Text("Subtitle"),
            //   trailing: Text(subName ?? "Unknown"),
            //   onTap: () => show<BetterPlayerSubtitlesSource>(
            //     context,
            //     menu: subtitlesMenu(context),
            //   ).then((value) {
            //     if (value == null || !context.mounted) return;
            //     controller(context).setupSubtitleSource(value);
            //     Navigator.pop(context);
            //   }),
            // ),
            //

            // if ((controller(context).betterPlayerAsmsAudioTracks ?? [])
            //     .isNotEmpty)
            //   ListTile(
            //     leading: SvgPicture.asset(conf(context).assetHelper.subtitle),
            //     title: const Text("Audio Track"),
            //     trailing: Text(audio?.label ?? audio?.language ?? "Unknown"),
            //     onTap: () => show<BetterPlayerAsmsAudioTrack>(
            //       context,
            //       menu: audioPickerMenu(context),
            //     ).then((value) {
            //       if (value == null || !context.mounted) return;
            //       controller(context).setAudioTrack(value);
            //       Navigator.pop(context);
            //     }),
            //   ),
            //

            ListTile(
              leading: SvgPicture.asset(
                conf(context).assetHelper.playbackSpeed,
              ),
              title: const Text("Playback Speed"),
              trailing: speed == 1.0 ? const Text("Normal") : Text("${speed}x"),
              onTap: () => show(
                context,
                menu: speedMenu(context),
              ).then((value) {
                if (value == null || !context.mounted) return;
                controller(context).setPlaybackSpeed(value);
                Navigator.pop(context);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _indicator(bool show) {
    return Icon(
      Icons.check_rounded,
      color: show ? null : Colors.transparent,
    );
  }

  Widget speedMenu(BuildContext context) {
    double current = context.read<PlayerState>().speed;

    return ListTileTheme(
      data: listTileTheme,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: DragHandle()),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Playback Speed"),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (double i in [0.25, 0.5, 1.0, 1.25, 1.5, 1.75, 2.0])
                    ListTile(
                      title: i == 1.0 ? const Text("Normal") : Text("${i}x"),
                      leading: _indicator(current == i),
                      onTap: () => Navigator.pop(context, i),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*

  Widget qualityPickerMenu(BuildContext context) {
    final now = controller(context).betterPlayerAsmsTrack;
    final auto = BetterPlayerAsmsTrack.defaultTrack();
    final tracks = controller(context).betterPlayerAsmsTracks;

    return ListTileTheme(
      data: listTileTheme,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: DragHandle()),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Quality for current video"),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text("Auto"),
                    leading: _indicator(now == auto),
                    onTap: () => Navigator.pop(context, auto),
                  ),
                  for (final track in tracks.where((e) => e != auto))
                    ListTile(
                      title: Text("${track.height}p"),
                      leading: _indicator(track == now),
                      onTap: () => Navigator.pop(context, track),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget audioPickerMenu(BuildContext context) {
    final tracks = controller(context).betterPlayerAsmsAudioTracks;
    final now =
        controller(context).betterPlayerAsmsAudioTrack ?? tracks?.firstOrNull;

    return ListTileTheme(
      data: listTileTheme,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: DragHandle()),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Select Audio"),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final track in tracks ?? <BetterPlayerAsmsAudioTrack>[])
                    ListTile(
                      title: Text(track.label ?? track.language ?? "Unknown"),
                      leading: _indicator(track == now),
                      onTap: () => Navigator.pop(context, track),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget subtitlesMenu(BuildContext context) {
    final now = controller(context).betterPlayerSubtitlesSource;
    final subs = controller(context).betterPlayerSubtitlesSourceList;
    final none = subs.firstWhere(
      (s) => s.type == BetterPlayerSubtitlesSourceType.none,
    );

    return ListTileTheme(
      data: listTileTheme,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: DragHandle()),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Subtitle"),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text("Turn Off"),
                    leading: _indicator(now == none),
                    onTap: () => Navigator.pop(context, none),
                  ),
                  for (final sub in subs.where((s) => s != none))
                    ListTile(
                      title: Text(sub.name ?? "Unknown"),
                      leading: _indicator(sub == now),
                      onTap: () => Navigator.pop(context, sub),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
*/
}
