import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/post_model.dart';

class PostMedia extends StatefulWidget {
  final PostModel post;

  const PostMedia({super.key, required this.post});

  @override
  State<PostMedia> createState() => _PostMediaState();
}

class _PostMediaState extends State<PostMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant PostMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.mediaUrl != widget.post.mediaUrl ||
        oldWidget.post.postType != widget.post.postType) {
      _disposeController();
      _init();
    }
  }

  Future<void> _init() async {
    if (widget.post.postType != PostType.video) return;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.mediaUrl),
    );
    _controller = controller;
    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(0);
    if (mounted) setState(() {});
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    c?.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.post.postType == PostType.video) {
      final c = _controller;
      if (c == null || !c.value.isInitialized) {
        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Video',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.post.mediaUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey[200]),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
    );
  }
}

