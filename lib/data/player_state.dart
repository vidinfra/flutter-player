// ignore_for_file: unnecessary_breaks

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goplayer/goplayer.dart';
import 'package:http/http.dart' as http;
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_preview_thumbnails/video_preview_thumbnails.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PlayerState extends ChangeNotifier {
  final GlobalKey _playerKey = GlobalKey();

  Media? _nowPlaying;
  Media? get nowPlaying => _nowPlaying;

  ControlsConfiguration _configuration = ControlsConfiguration();
  ControlsConfiguration get configuration => _configuration;

  // final CastManager castManager = CastManager();

  VideoPlayerController? _controller;
  VideoPlayerController? get controller => _controller;
  VideoPlayerValue? get player => _controller?.value;

  final thumbnailController = VideoPreviewThumbnailsController();

  final List<Media> _playlist = List.empty(growable: true);
  List<Media> get playlist => List.of(_playlist);

  /// Initializer
  PlayerState(BuildContext context) {
    // _controller = VideoPlayerController.networkUrl(
    //   betterPlayerConfiguration?.copyWith(autoDispose: false) ??
    //       BetterPlayerConfiguration(
    //         autoPlay: true,
    //         autoDispose: false,
    //         fit: BoxFit.contain,
    //         subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
    //           outlineEnabled: false,
    //           bgDecoration: BoxDecoration(
    //             color: const Color(0xA101081A),
    //             borderRadius: BorderRadius.circular(2),
    //           ),
    //         ),
    //       ),
    // );

    // _nowPlaying.addListener(_updateDataSource);
    // _updateDataSource();
    // _controller.addEventsListener(_eventListener);

    VolumeController.instance.showSystemUI = false;

    VolumeController.instance.getVolume().then((value) => _volume = value);
    ScreenBrightness.instance.application.then((value) => _brightness = value);
  }

  void play(Media media) {
    _controller?.dispose();
    _nowPlaying = media;

    final closedCaption = media.subtitles.firstOrNull;

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(media.url),
      httpHeaders: media.headers ?? {},
      //closedCaptionFile: Future.value(closedCaption),
    );

    _controller!.initialize().then((_) {
      //temp
      configuration.onCastClick?.call();
    });

    _controller?.addListener(_eventListener);

    _loadVttThumbnails();
    notifyListeners();
  }

  /// Null if not playing media from playlist
  int? get nowPlayingIndexInPlaylist {
    if (nowPlaying == null) return null;
    final index = _playlist.indexOf(nowPlaying!);
    return index == -1 ? null : index;
  }

  bool get loading {
    if (forwardGestureApplied || backwardGestureApplied) return false;
    if (_nowPlaying == null) return false;
    if (_bufferingAfterSeek) return true;
    if (player?.isInitialized != true) return true;
    if (_bufferingFresh) return true;
    if (_error) return false;
    return false;
  }

  Duration? _duration, _progress, _buffer;

  Duration? get duration {
    return player?.duration;
    // if (_controller.isLiveStream()) return null;
    return _duration;
  }

  Duration? get progress => player?.position;
  Duration? get buffer => _buffer;

  bool _userIsSeeking = false;
  bool get userIsSeeking => _userIsSeeking;

  bool _bufferingAfterSeek = false;

  double _speed = 1.0;
  double get speed => _speed;

  double _volume = 0.5;
  double get volume => _volume;

  double _brightness = 0.5;
  double get brightness => _brightness;

  bool _error = false;
  bool get error => _error;

  Uint8List? _vttFile;
  Uint8List? get thumbnailVTT => _vttFile;
  ui.Image? _vttSprite;
  ui.Image? get thumbnailSprite => _vttSprite;

  bool _bufferingFresh = false;

  void applyBrightness(double brightness) {
    _brightness = brightness;
    ScreenBrightness.instance.setApplicationScreenBrightness(brightness);

    // if (_controller.isFullScreen && !isInPip) {
    //   _brightnessGestureApplied = true;
    //   _volumeGestureApplied = false;
    //   notifyListeners();
    //   restartGestureHideTimer();
    // }
  }

  void applyConfiguration(ControlsConfiguration? controlsConfiguration) {
    if (controlsConfiguration == null) return;
    _configuration = controlsConfiguration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _eventListener() {
    // switch (event.betterPlayerEventType) {
    //   case BetterPlayerEventType.setupDataSource:
    //     _duration = null;
    //     _progress = null;
    //     _buffer = null;
    //     _error = false;
    //     break;

    //   case BetterPlayerEventType.pause:
    //     WakelockPlus.disable();
    //     break;
    //   case BetterPlayerEventType.play:
    //     _bufferingFresh = false;
    //     WakelockPlus.enable();
    //     break;

    //   case BetterPlayerEventType.seekTo:
    //     _bufferingAfterSeek = false;
    //     break;

    //   case BetterPlayerEventType.progress:
    //     if (_bufferingAfterSeek) break;
    //     if (_controller.isLiveStream()) {
    //       _duration = null;
    //       _progress = null;
    //     } else {
    //       _duration = event.parameters?["duration"];
    //       _progress = event.parameters?["progress"];

    //       if (!userIsSeeking && nextEpisodeAutoStartTime != null) {
    //         // Don't skip if seeked further than confirmation time
    //         final maxTrigger = nextEpisodeAutoStartTime! +
    //             configuration.creditSkipConfirmDuration;

    //         if (nextEpisodeAutoStartTime!.isNegative &&
    //             maxTrigger >= Duration.zero) {
    //           skipToNextEpisode();
    //         }
    //       }
    //     }
    //     break;

    //   case BetterPlayerEventType.finished:
    //     _videoEndHandler();
    //     break;

    //   case BetterPlayerEventType.bufferingStart:
    //     _bufferingFresh = true;
    //     _buffer = null;
    //     break;

    //   case BetterPlayerEventType.bufferingUpdate:
    //     if (event.parameters == null) break;
    //     _buffer = event.parameters?["buffered"].last.end;
    //     _bufferingFresh = false;
    //     break;

    //   case BetterPlayerEventType.bufferingEnd:
    //     _bufferingFresh = false;
    //     break;

    //   case BetterPlayerEventType.pipStart:
    //     _pipModeActive = true;
    //     break;

    //   case BetterPlayerEventType.pipStop:
    //     _pipModeActive = false;
    //     break;

    //   case BetterPlayerEventType.setSpeed:
    //     _speed = event.parameters?["speed"];
    //     showChipMessage("Playback speed at ${_speed}x");
    //     break;

    //   case BetterPlayerEventType.exception:
    //     _bufferingFresh = false;
    //     _buffer = null;
    //     _error = true;
    //     break;

    //   case BetterPlayerEventType.hideFullscreen:
    //     ScreenBrightness.instance.resetApplicationScreenBrightness();
    //     toggleFit(override: BoxFit.contain);
    //     break;

    //   default:
    //     break;
    // }
    if (!_disposed) notifyListeners();
  }

  void enqueue(List<Media> list, {int? startPlayingFrom}) {
    _playlist.clear();
    _playlist.addAll(list);
    if (startPlayingFrom != null) play(list[startPlayingFrom]);
  }

  void Function(bool)? _visibilityCallBack;

  /// NOTE: overlay widgets must be wrapped with Positioned
  void setCustomOverlays(BuildContext context, List<Widget> overlays) {
    // _controller.setBetterPlayerControlsConfiguration(
    //   BetterPlayerControlsConfiguration(
    //     playerTheme: BetterPlayerTheme.custom,
    //     customControlsBuilder: (_, visibility) {
    //       _visibilityCallBack = visibility;
    //       return ChangeNotifierProvider<PlayerState>.value(
    //         value: this,
    //         child: Stack(alignment: Alignment.center, children: overlays),
    //       );
    //     },
    //   ),
    // );
  }

  void _updateDataSource({String? url}) async {
    // final media = _nowPlaying.value;
    // if (media == null) {
    //   // TODO Reset State
    //   return;
    // }
    // if ((url ?? media.url) == _controller.betterPlayerDataSource?.url) return;

    // _controller.clearCache();
    // _controller.betterPlayerAsmsTracks.clear();
    // _controller.betterPlayerAsmsAudioTracks?.clear();
    // _controller.betterPlayerSubtitlesSourceList.clear();
    // notifyListeners();

    // final dataSource = BetterPlayerDataSource.network(
    //   url ?? media.preClipUrl ?? media.url,
    //   liveStream: media.isLive,
    //   useAsmsSubtitles: true,
    //   useAsmsTracks: true,
    //   useAsmsAudioTracks: true,
    //   headers: media.headers,
    //   drmConfiguration: media.drmConfiguration,
    //   bufferingConfiguration: BetterPlayerBufferingConfiguration(
    //     minBufferMs: const Duration(seconds: 10).inMilliseconds,
    //     // Prevents OOM
    //     maxBufferMs: const Duration(minutes: 5).inMilliseconds,
    //   ),
    //   subtitles: media.subtitles,
    // );

    // await _controller.setupDataSource(dataSource);
    // _loadVttThumbnails();

    // // We should also seek to last played position here
    // if (!_controller.isLiveStream()) _controller.seekTo(Duration.zero);
  }

  bool _locked = false;

  bool get locked => _locked;

  bool _controlsVisible = false;

  bool get controlsVisible {
    if (_pipModeActive || _error) return false;
    return _controlsVisible;
  }

  void toggleLock() {
    _locked = !_locked;
    if (!locked) showChipMessage("Screen Unlocked");
    notifyListeners();
  }

  bool get isExpandedFit => false; // _controller.getFit() == BoxFit.cover;

  void toggleFit({BoxFit? override}) {
    // if (override != null) {
    //   _controller.setOverriddenFit(override);
    // } else {
    //   _controller.setOverriddenFit(
    //     isExpandedFit ? BoxFit.contain : BoxFit.cover,
    //   );
    // }
    notifyListeners();
  }

  void seekTo(Duration toPosition) async {
    _progress = toPosition;
    _bufferingAfterSeek = true;
    notifyListeners();
    await _controller?.seekTo(_progress!);
  }

  void toggleControls() {
    _controlsVisible = !_controlsVisible;
    _visibilityCallBack?.call(_controlsVisible);
    if (_controlsVisible) restartControlsHideTimer();
    notifyListeners();
  }

  bool _pipModeActive = false;

  bool get isInPip => _pipModeActive;

  void launchPip() {
    // _controller.enablePictureInPicture(_playerKey);
  }

  void launchCast(BuildContext context) {
    // showDialog(
    //   context: context,
    //   builder: (context) => ChangeNotifierProvider.value(
    //     value: this,
    //     child: const CastDevicePicker(),
    //   ),
    // );
  }

  void retry() {
    _bufferingFresh = true;
    // _controller.retryDataSource();
    _error = false;
    notifyListeners();
  }

  Timer? _hideControlsTimer, _hideGestureTimer, _chipMessageTimer;

  bool _forwardGestureApplied = false, _backwardGestureApplied = false;
  bool _volumeGestureApplied = false, _brightnessGestureApplied = false;
  bool get forwardGestureApplied => _forwardGestureApplied;
  bool get backwardGestureApplied => _backwardGestureApplied;
  bool get volumeGestureApplied => _volumeGestureApplied;
  bool get brightnessGestureApplied => _brightnessGestureApplied;

  void seekGesture({required bool forward}) {
    if (_progress == null || _duration == null) return;

    _forwardGestureApplied = forward;
    _backwardGestureApplied = !forward;
    _controlsVisible = false;
    notifyListeners();

    var toPosition = _progress!;
    if (forward) {
      toPosition += _configuration.seekGestureDuration;
    } else {
      toPosition -= _configuration.seekGestureDuration;
    }

    if (toPosition < Duration.zero) toPosition = Duration.zero;
    if (toPosition > _duration!) toPosition = _duration!;

    seekTo(toPosition);

    restartGestureHideTimer();
    notifyListeners();
  }

  void restartGestureHideTimer() {
    _hideGestureTimer?.cancel();
    _hideGestureTimer = Timer(Durations.extralong4, () {
      _forwardGestureApplied = false;
      _backwardGestureApplied = false;
      _volumeGestureApplied = false;
      _brightnessGestureApplied = false;
      notifyListeners();
    });
  }

  void restartControlsHideTimer() {
    cancelControlsHideTimer();
    _hideControlsTimer = Timer(_configuration.autoHideDuration, () {
      _controlsVisible = false;
      _visibilityCallBack?.call(_controlsVisible);
      notifyListeners();
    });
  }

  void cancelControlsHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
  }

  /// Volume isn't smooth because android fewer steps 0-8
  /// as opposed to brightness 0-100
  void setVolume(double volume) {
    _volume = volume;
    _volumeGestureApplied = true;
    _brightnessGestureApplied = false;
    notifyListeners();
    restartGestureHideTimer();
    VolumeController.instance.setVolume(volume);
  }

  void _loadVttThumbnails() async {
    if (nowPlaying?.thumbnailVTTUrl == null) {
      _vttFile = null;
      _vttSprite = null;
      notifyListeners();
      return;
    }

    http.Response response = await http.get(Uri.parse(
      nowPlaying!.thumbnailVTTUrl!,
    ));

    _vttFile = response.bodyBytes;
    final String vttData = String.fromCharCodes(_vttFile!);
    final controller = VttDataController.string(vttData);

    if (_disposed) return;

    http.Response image = await http.get(Uri.parse(
      nowPlaying!.thumbVTTBaseUrl + controller.vttData.first.imageUrl,
    ));

    _vttSprite = await _loadUiImage(image.bodyBytes);

    if (_disposed) return;
    notifyListeners();
  }

  Future<ui.Image> _loadUiImage(final Uint8List img) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromList(img, completer.complete);
    return completer.future;
  }

  void setUserIsSeeking(bool value) {
    _userIsSeeking = value;
    if (_progress != null) {
      Future.delayed(Durations.short2, () {
        thumbnailController.setCurrentTime((_progress!.inMilliseconds).toInt());
      });
    }

    if (_userIsSeeking) {
      cancelControlsHideTimer();
    } else {
      restartControlsHideTimer();
    }

    notifyListeners();
  }

  bool get introSkippable {
    if (nowPlaying == null) return false;
    final nowUrl = _controller!.dataSource;
    // Pre/Post clip is playing
    if (nowUrl != nowPlaying!.url) return false;

    if (_progress != null && nowPlaying!.introEnd != null) {
      if (nowPlaying!.introStart != null) {
        if (_progress! < nowPlaying!.introStart!) return false;
      }
      if (_progress! < nowPlaying!.introEnd!) return true;
    }

    return false;
  }

  void skipIntro() {
    if (!introSkippable) return;
    seekTo(nowPlaying!.introEnd!);
    showChipMessage("Intro Skipped");
    notifyListeners();
  }

  bool _shouldSkipCredits = true;

  String? _chipMessage;
  String? get chipMessage => _chipMessage;

  void showChipMessage(String msg) {
    _chipMessageTimer?.cancel();
    _chipMessage = msg;
    notifyListeners();
    _chipMessageTimer = Timer(const Duration(seconds: 2), () {
      _chipMessage = null;
      notifyListeners();
    });
  }

  bool get willSkipCredit {
    return canSkipToNextEpisode && _shouldSkipCredits;
  }

  void dontSkipCredit() {
    _shouldSkipCredits = false;
    notifyListeners();
  }

  Duration? get nextEpisodeAutoStartTime {
    if (_progress == null || !_shouldSkipCredits) return null;
    if (nowPlaying == null || nowPlaying!.creditStart == null) return null;
    final skipAt =
        nowPlaying!.creditStart! + configuration.creditSkipConfirmDuration;

    final timeLeft = skipAt - _progress!;
    return timeLeft;
  }

  bool get canSkipToNextEpisode {
    if (playlist.isEmpty) return false;
    final nowUrl = _controller!.dataSource;
    // Pre/Post clip is playing
    if (nowUrl != nowPlaying!.url) return false;

    if (nowPlayingIndexInPlaylist == null ||
        !(nowPlayingIndexInPlaylist! < playlist.length)) return false;

    if (_progress != null && nowPlaying!.creditStart != null) {
      if (_progress! >= nowPlaying!.creditStart!) return true;
    }

    return false;
  }

  void skipToNextEpisode() {
    // if (!canSkipToNextEpisode) return;
    // //_nowPlaying.value = playlist[nowPlayingIndexInPlaylist! + 1];
    // _shouldSkipCredits = true;
    // configuration.onMediaEnd?.call();
    // showChipMessage("Outro Skipped");
    notifyListeners();
  }

  void _videoEndHandler() {
    // final nowUrl = _controller.betterPlayerDataSource!.url;
    // if (nowPlaying!.postClipUrl != null && nowUrl == nowPlaying!.url) {
    //   // Has post clip, Play it
    //   return _updateDataSource(url: nowPlaying!.postClipUrl);
    // } else if (nowPlaying!.preClipUrl != null &&
    //     nowUrl == nowPlaying!.preClipUrl) {
    //   // Was playing pre clip, Start actual media
    //   return _updateDataSource(url: nowPlaying!.url);
    // }

    // if (configuration.onMediaEnd != null) {
    //   return configuration.onMediaEnd!.call();
    // }

    // if (_playlist.isNotEmpty) {
    //   final next = (nowPlayingIndexInPlaylist ?? -1) + 1;
    //   _nowPlaying.value = _playlist[next];
    // }
  }

  bool _disposed = false;

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
    _controller?.removeListener(_eventListener);
    _controller?.dispose();
    thumbnailController.dispose();
    VolumeController.instance.removeListener();
    ScreenBrightness.instance.resetApplicationScreenBrightness();
    WakelockPlus.disable();

    _hideControlsTimer?.cancel();
    _hideGestureTimer?.cancel();
    _chipMessageTimer?.cancel();

    _visibilityCallBack = null;
  }
}
