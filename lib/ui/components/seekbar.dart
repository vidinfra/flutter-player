import 'package:flutter/material.dart';
import 'package:goplayer/goplayer.dart';
import 'package:provider/provider.dart';

class SeekBar extends StatefulWidget {
  const SeekBar({super.key});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  PlayerState state(BuildContext context) => context.read<PlayerState>();
  double _seekedPosition = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerState>(
      builder: (context, state, child) {
        final duration = state.duration;
        final buffer = state.buffer;
        if (duration == null) return const SizedBox();

        final progress = state.progress!.inSeconds.toDouble();

        return Slider(
          value: state.userIsSeeking ? _seekedPosition : progress,
          secondaryTrackValue: buffer?.inSeconds.toDouble() ?? 0,
          max: duration.inSeconds.toDouble(),
          onChangeStart: (value) => setState(() {
            state.setUserIsSeeking(true);
            _seekedPosition = value;
          }),
          onChanged: (value) {
            setState(() => _seekedPosition = value);
            state.thumbnailController.setCurrentTime((value * 1000).toInt());
          },
          onChangeEnd: (value) {
            setState(() {
              _seekedPosition = value;
              state.setUserIsSeeking(false);
            });
            state.seekTo(
              Duration(seconds: _seekedPosition.toInt()),
            );
          },
        );
      },
    );
  }
}
