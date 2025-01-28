import 'package:video_player/video_player.dart';

class Media {
  final String title;
  final String url;
  final bool isLive;

  final String? poster;
  final String? thumbnailVTTUrl;

  final Map<String, String>? headers;

  final List<ClosedCaptionFile> subtitles;

  final Duration? introStart, introEnd, creditStart;

  final String? preClipUrl, postClipUrl;

  String get thumbVTTBaseUrl {
    assert(thumbnailVTTUrl != null);
    Uri uri = Uri.parse(thumbnailVTTUrl!);

    final segments = List.of(uri.pathSegments);
    segments.removeLast();

    return "${uri.replace(pathSegments: segments)}/";
  }

  const Media({
    required this.title,
    required this.url,
    this.isLive = false,
    this.poster,
    this.thumbnailVTTUrl,
    this.headers,
    this.subtitles = const [],
    this.introStart,
    this.introEnd,
    this.creditStart,
    this.preClipUrl,
    this.postClipUrl,
  });
}
