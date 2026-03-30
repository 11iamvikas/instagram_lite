// lib/features/create_post/screens/create_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/post_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/repositories/post_repository.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  File? _mediaFile;
  PostType _postType = PostType.image;
  final _captionController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _mediaFile = File(picked.path);
        _postType = PostType.image;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _mediaFile = File(picked.path);
        _postType = PostType.video;
      });
    }
  }

  Future<void> _createPost() async {
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image or video')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(' ')
          .where((t) => t.startsWith('#'))
          .toList();

      await ref.read(postRepositoryProvider).createPost(
            uid: currentUser.uid,
            username: currentUser.username,
            userPhotoUrl: currentUser.photoUrl,
            mediaFile: _mediaFile!,
            postType: _postType,
            caption: _captionController.text.trim(),
            tags: tags,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared successfully!')),
        );
        context.go('/feed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Share',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media preview / picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  image: _mediaFile != null && _postType == PostType.image
                      ? DecorationImage(
                          image: FileImage(_mediaFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _mediaFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to select a photo',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : _postType == PostType.video
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Video selected',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : null,
              ),
            ),
            const SizedBox(height: 12),

            // Pick buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Video'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Caption
            TextField(
              controller: _captionController,
              maxLines: 4,
              maxLength: 2200,
              decoration: const InputDecoration(
                labelText: 'Write a caption...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (e.g. #flutter #firebase)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
