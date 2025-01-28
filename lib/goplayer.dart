export 'package:video_player/video_player.dart';

export 'data/ima_state.dart';
export 'data/models/controls_configuration.dart';
export 'data/models/media.dart';
export 'data/player_state.dart';
export 'ui/components/drag_handle.dart';
export 'ui/components/gesture_handler.dart';
export 'ui/components/ima_view.dart';
export 'ui/components/message_chip.dart';
export 'ui/components/seekbar.dart';
export 'ui/controls/player_controls.dart';
export 'ui/controls/settings_menu.dart';
export 'ui/player_view.dart';

extension DurationExtensions on Duration? {
  String formatHHMMSS() {
    if (this == null) return "??:??";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitMinutes = twoDigits(this!.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(this!.inSeconds.remainder(60));
    final hour = twoDigits(this!.inHours);
    return " ${hour == '00' ? '' : '$hour:'}$twoDigitMinutes:$twoDigitSeconds ";
  }
}


class PlayerAssetHelper {
  final _controlIcons = "packages/goplayer/assets/control_icons";
  final _lottie = "packages/goplayer/assets/lottie";

  String get backButton => "$_controlIcons/back_button.svg";
  String get episodes => "$_controlIcons/episodes.svg";
  String get fitContain => "$_controlIcons/fit_contain.svg";
  String get fitCover => "$_controlIcons/fit_cover.svg";
  String get lock => "$_controlIcons/lock.svg";
  String get nextEpisode => "$_controlIcons/next_episode.svg";
  String get pause => "$_controlIcons/pause.svg";
  String get pip => "$_controlIcons/pip.svg";
  String get play => "$_controlIcons/play.svg";
  String get replay => "$_controlIcons/replay.svg";
  String get screenCast => "$_controlIcons/screen_cast.svg";
  String get settings => "$_controlIcons/settings.svg";
  String get unlock => "$_controlIcons/unlock.svg";

  String get playbackSpeed => "$_controlIcons/playback.svg";
  String get quality => "$_controlIcons/quality.svg";
  String get subtitle => "$_controlIcons/subtitle.svg";
  String get rotate => "$_controlIcons/rotate.svg";

  String get brightness => "$_controlIcons/brightness.svg";
  String get volumeMute => "$_controlIcons/volume_mute.svg";
  String get volumeLow => "$_controlIcons/volume_low.svg";
  String get volumeHigh => "$_controlIcons/volume_high.svg";

  String get lottieBackward => "$_lottie/backward.json";
  String get lottieForward => "$_lottie/forward.json";
}

extension DoubleExtensions on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}
