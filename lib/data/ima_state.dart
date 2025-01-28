import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goplayer/data/player_state.dart';
import 'package:interactive_media_ads/interactive_media_ads.dart';
import 'package:video_player/video_player.dart';

class IMAState extends ChangeNotifier with WidgetsBindingObserver {
  final String adTagUrl;
  final PlayerState playerState;
  IMAState(this.adTagUrl, {required this.playerState}) {
    // playerController.addEventsListener(_playerEventListener);
  }

  String? _poster;
  String? get poster => _poster;

  void setBackgroundPoster(String? url) {
    _poster = url;
    notifyListeners();
  }

  // void _playerEventListener(BetterPlayerEvent event) {
  //   switch (event.betterPlayerEventType) {
  //     case BetterPlayerEventType.play:
  //       if (!_shouldShowVideo) playerController.pause();

  //     case BetterPlayerEventType.finished:
  //       if (playerState.nowPlaying!.url ==
  //           playerState.controller.betterPlayerDataSource!.url) {
  //         // Don't trigger for pre post clips
  //         _adsLoader.contentComplete();
  //       }

  //     default:
  //       break;
  //   }
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _adsManager?.resume();
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    // playerController.removeEventsListener(_playerEventListener);
    _adsLoader.contentComplete();
    _adsManager?.destroy();
    _contentProgressTimer?.cancel();
    super.dispose();
  }

  VideoPlayerController get playerController => playerState.controller!;

  // The AdsLoader instance exposes the request ads method.
  late final AdsLoader _adsLoader;
  bool _adsLoaderInitialized = false;

  // AdsManager exposes methods to control ad playback and listen to ad events.
  AdsManager? _adsManager;

  // ···
  // Whether the widget should be displaying the content video. The content
  // player is hidden while Ads are playing.
  // Ads can't be requested until the `AdDisplayContainer` has been added to
  // the native View hierarchy.
  bool _shouldShowVideo = false;
  bool get shouldShowVideo => _shouldShowVideo;

  bool _showAdsLoading = false;
  bool get showAdsLoading => _showAdsLoading;

  // Controls the content video player.
  // Periodically updates the SDK of the current playback progress of the
  // content video.
  Timer? _contentProgressTimer;

  // Provides the SDK with the current playback progress of the content video.
  // This is required to support mid-roll ads.
  final ContentProgressProvider _contentProgressProvider =
      ContentProgressProvider();

  late final AdDisplayContainer adDisplayContainer = AdDisplayContainer(
    onContainerAdded: _initializeAdsLoader,
  );

  void _initializeAdsLoader(AdDisplayContainer container) {
    if (_adsLoaderInitialized) return;
    _adsLoader = AdsLoader(
      container: container,
      onAdsLoaded: (OnAdsLoadedData data) {
        _adsManager = data.manager;

        _adsManager?.setAdsManagerDelegate(AdsManagerDelegate(
          onAdEvent: (AdEvent event) {
            if (_disposed) return;
            print('OnAdEvent: ${event.type} => ${event.adData}');
            switch (event.type) {
              case AdEventType.loaded:
                _adsManager?.start();

              case AdEventType.contentPauseRequested:
                _pauseContent();

              case AdEventType.started:
                _showAdsLoading = false;
                notifyListeners();

              case AdEventType.adProgress:
                _showAdsLoading = false;
                notifyListeners();

              case AdEventType.contentResumeRequested:
                _resumeContent();

              case AdEventType.allAdsCompleted:
                _adsManager?.destroy();
                _adsManager = null;

              default:
                break;
            }
          },
          onAdErrorEvent: (AdErrorEvent event) {
            if (_disposed) return;
            print('AdErrorEvent: ${event.error.message}');
            playerState.showChipMessage("Ads Loading Failed");
            _resumeContent();
          },
        ));

        _adsManager?.init(
          settings: AdsRenderingSettings(
            enablePreloading: true,
            uiElements: AdUIElement.values.toSet(),
          ),
        );
      },
      onAdsLoadError: (AdsLoadErrorData data) {
        if (_disposed) return;
        print('OnAdsLoadError: ${data.error.message}');
        _resumeContent();
        playerState.showChipMessage("Ads Loading Failed");
      },
    );

    _adsLoaderInitialized = true;
    _requestAds();
  }

  // Ads can't be requested until the `AdDisplayContainer` has been added to
  // the native View hierarchy.
  void _requestAds() {
    if (!_adsLoaderInitialized) return;
    _adsManager?.destroy();
    _adsManager = null;
    _shouldShowVideo = true;
    _showAdsLoading = true;
    notifyListeners();

    _adsLoader.requestAds(AdsRequest(
      adTagUrl: adTagUrl,
      contentProgressProvider: _contentProgressProvider,
    ));
  }

  Future<void> _resumeContent() async {
    _showAdsLoading = false;
    _shouldShowVideo = true;
    notifyListeners();

    if (_adsManager != null) {
      _contentProgressTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (timer) async {
          if (playerState.nowPlaying == null) return;
          if (playerState.duration == null) return;
          if (playerState.progress == null) return;
          if (playerState.duration == playerState.progress) {
            _adsLoader.contentComplete();
            return;
          }
          await _contentProgressProvider.setProgress(
            progress: playerState.progress!,
            duration: playerState.duration!,
          );
        },
      );
    }

    playerController.play();
  }

  void _pauseContent() async {
    _showAdsLoading = true;
    // if (playerController.isLiveStream() || playerState.isInPip) {
    //   _adsManager?.skip();
    //   notifyListeners();
    //   return;
    // }

    _shouldShowVideo = false;
    playerController.pause();
    _contentProgressTimer?.cancel();
    _contentProgressTimer = null;
    notifyListeners();
  }
}
