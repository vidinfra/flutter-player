import 'package:flutter/material.dart';
import 'package:goplayer/goplayer.dart';
import 'package:provider/provider.dart';

class GestureHandler {
  PlayerState get state => context.read<PlayerState>();
  final BuildContext context;
  GestureHandler(this.context);

  void onDoubleTapDown(TapDownDetails details) {
    if (state.locked) return;
    // if (state.controller.isLiveStream()) return;
    final width = MediaQuery.of(context).size.width;
    final offset = width / 6;
    final midpoint = width / 2;

    final tapPosition = details.localPosition.dx;
    bool rightSide = tapPosition - offset > width / 2;

    // Offset guard
    if (rightSide) {
      if (tapPosition - offset < midpoint) return;
    } else {
      if (tapPosition + offset > midpoint) return;
    }

    state.seekGesture(forward: rightSide);
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    if (state.locked) return;
    // if (!state.controller.isFullScreen) return;
    final width = MediaQuery.of(context).size.width;

    bool isBrightnessArea = details.localPosition.dx < width / 4;
    bool isVolumeArea = details.localPosition.dx > (width - width / 4);

    if (isVolumeArea) {
      double volume = state.volume;
      final height = MediaQuery.of(context).size.height;

      volume -= (details.primaryDelta! * 4) / height;
      volume = volume.clamp(0.0, 1.0).toPrecision(2);

      state.setVolume(volume);
    }

    if (isBrightnessArea) {
      double brightness = state.brightness;
      final height = MediaQuery.of(context).size.height;

      brightness -= (details.primaryDelta! * 4) / height;
      brightness = brightness.clamp(0.0, 1.0).toPrecision(2);

      state.applyBrightness(brightness);
    }
  }
}
