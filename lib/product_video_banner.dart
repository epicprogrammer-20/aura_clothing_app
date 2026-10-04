import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Autoplaying, muted, looping product-ad banner for the bottom of the
/// Home feed. There's no audio track on the source video, so autoplay
/// needs no user gesture and there's nothing lost by looping it silently
/// like a "living photo".
///
/// Shows a poster frame immediately (no flash of black/spinner while the
/// video initializes) and falls back to that same poster if the video
/// ever fails to load.
class ProductVideoBanner extends StatefulWidget {
  const ProductVideoBanner({super.key});

  @override
  State<ProductVideoBanner> createState() => _ProductVideoBannerState();
}

class _ProductVideoBannerState extends State<ProductVideoBanner> with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset('assets/videos/aura_product_ad.mp4');
    _controller
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _failed = true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause while backgrounded so it isn't silently burning battery/data,
    // resume when the app comes back to the foreground.
    if (!_ready || _failed) return;
    if (state == AppLifecycleState.resumed) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster frame — visible until the video is ready, and stays
              // as the fallback if playback ever fails.
              Image.asset(
                'assets/images/banners/aura_video_poster.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
              ),
              if (_ready && !_failed)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              // Small muted badge — sets expectations before anyone taps it,
              // since there's no sound to unmute anyway.
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_off, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('AURA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
