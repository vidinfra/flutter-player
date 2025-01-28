import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:goplayer/data/player_state.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../data/models/controls_configuration.dart';
import 'controls/player_controls.dart';

class PlayerView extends StatelessWidget {
  final PlayerState state;
  final bool defaultOverlays;
  final ControlsConfiguration? controlsConfiguration;

  /// Must be wrapped with Positioned
  final List<Widget> overlays;

  PlayerView(
    BuildContext context, {
    super.key,
    required this.state,
    this.overlays = const [],
    this.defaultOverlays = true,
    this.controlsConfiguration,
  }) {
    state.applyConfiguration(controlsConfiguration);
    state.setCustomOverlays(context, []);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ChangeNotifierProvider.value(
            value: state,
            child: Consumer<PlayerState>(
              builder: (_, state, ___) => SizedBox(
                child: Stack(
                  children: [
                    if (state.nowPlaying != null)
                      Positioned.fill(child: VideoPlayer(state.controller!)),
                    // if (defaultOverlays) posterWidget(context),
                    if (defaultOverlays)
                      const Positioned.fill(child: PlayerControls()),
                    if (defaultOverlays) loadingIndicatorWidget(context),
                    if (defaultOverlays) errorIndicatorWidget(context),
                  ],
                ),
              ),
            ),
          ),
        ),
        ...overlays,
      ],
    );
  }

  Widget posterWidget(BuildContext context) {
    return Positioned.fill(
      child: Consumer<PlayerState>(
        builder: (_, state, __) {
          final played = state.player?.isInitialized == true;
          if (state.nowPlaying?.poster == null || played) {
            return const SizedBox.shrink();
          }

          return ColoredBox(
            color: Colors.black,
            child: CachedNetworkImage(
              imageUrl: state.nowPlaying!.poster!,
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }

  Widget loadingIndicatorWidget(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Selector<PlayerState, bool>(
        selector: (_, p) => p.loading,
        builder: (context, loading, _) {
          if (!loading) return const SizedBox.shrink();
          return SizedBox.fromSize(
            size: const Size.square(60),
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        },
      ),
    );
  }

  Widget errorIndicatorWidget(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Selector<PlayerState, bool>(
        selector: (_, p) => p.error,
        builder: (_, error, __) {
          if (!error) return const SizedBox.shrink();
          return Material(
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: double.maxFinite),
                const Text(
                  "Something went wrong!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We are having trouble to play this video"
                  "\nright now. Please try again later.",
                  textAlign: TextAlign.center,
                ),
                FilledButton.icon(
                  autofocus: true,
                  label: const Text("Retry"),
                  icon: const Icon(Icons.sync_rounded),
                  onPressed: () => state.retry(),
                ),
                TextButton(
                  autofocus: true,
                  onPressed: state.configuration.onBackPress ??
                      () => Navigator.pop(context),
                  child: const Text("Go Back"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
