// Preview adapter for youtube_player_iframe: a placeholder player that keeps
// the controller API the app drives, with no web view underneath.
import 'dart:async';

import 'package:flutter/material.dart';

enum PlayerState { unknown, unStarted, ended, playing, paused, buffering, cued }

class YoutubePlayerParams {
  const YoutubePlayerParams({
    this.mute = false,
    this.showControls = true,
    this.showFullscreenButton = false,
    this.privacyEnhancedMode = false,
    this.enableCaption = false,
    this.loop = false,
    this.playsInline = true,
    this.strictRelatedVideos = false,
  });
  final bool mute;
  final bool showControls;
  final bool showFullscreenButton;
  final bool privacyEnhancedMode;
  final bool enableCaption;
  final bool loop;
  final bool playsInline;
  final bool strictRelatedVideos;
}

class YoutubePlayerController {
  YoutubePlayerController({String? key, this.params = const YoutubePlayerParams()});
  final YoutubePlayerParams params;
  String? _url;
  PlayerState _state = PlayerState.unStarted;
  Future<PlayerState> get playerState async => _state;
  Future<void> cueVideoByUrl({required String mediaContentUrl, double? startSeconds}) async {
    _url = mediaContentUrl;
    _state = PlayerState.cued;
  }
  Future<void> loadVideoById({required String videoId, double? startSeconds}) async {
    _url = videoId;
    _state = PlayerState.playing;
  }
  Future<void> playVideo() async => _state = PlayerState.playing;
  Future<void> pauseVideo() async => _state = PlayerState.paused;
  Future<void> stopVideo() async => _state = PlayerState.ended;
  Future<void> close() async {}
  String get videoUrl => _url ?? '';
}

class YoutubePlayerControllerProvider extends InheritedWidget {
  const YoutubePlayerControllerProvider({super.key, required this.controller, required super.child});
  final YoutubePlayerController controller;
  @override
  bool updateShouldNotify(YoutubePlayerControllerProvider oldWidget) => controller != oldWidget.controller;
}

class YoutubePlayer extends StatelessWidget {
  const YoutubePlayer({super.key, required this.controller, this.aspectRatio = 16 / 9});
  final YoutubePlayerController controller;
  final double aspectRatio;
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 64, semanticLabel: 'YouTube video'),
      ),
    );
  }
}
