import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seattle_pulse_mobile/src/core/constants/constants.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/feed_card.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/providers/add_story_notifier.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/providers/add_story_provider.dart';
import 'package:seattle_pulse_mobile/src/features/add-story/screens/location_step.dart';
// Import your FeedScreen widget (adjust the import path as needed)
import 'package:seattle_pulse_mobile/src/features/feed/screens/feed_screen.dart';

/// Data model for the story
class StoryData {
  final File? image;
  final String caption;
  final String location;
  final double? latitude;
  final double? longitude;

  StoryData({
    this.image,
    this.caption = '',
    this.location = '',
    this.latitude,
    this.longitude,
  });

  StoryData copyWith({
    File? image,
    String? caption,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return StoryData(
      image: image ?? this.image,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// StateNotifier for managing StoryData
class StoryNotifier extends StateNotifier<StoryData> {
  StoryNotifier() : super(StoryData());

  void setImage(File? image) {
    state = state.copyWith(image: image);
  }

  void setCaption(String caption) {
    state = state.copyWith(caption: caption);
  }

  void setLocation(String location) {
    state = state.copyWith(location: location);
  }

  void setCoordinates(double? latitude, double? longitude) {
    state = state.copyWith(latitude: latitude, longitude: longitude);
  }

  void setLocationData(String location, double? latitude, double? longitude) {
    state = state.copyWith(
      location: location,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

final storyProvider = StateNotifierProvider<StoryNotifier, StoryData>((ref) {
  return StoryNotifier();
});

/// Main screen to add a story
class AddStoryScreen extends ConsumerStatefulWidget {
  const AddStoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends ConsumerState<AddStoryScreen> {
  final PageController _pageController = PageController();
  final int _totalPages = 4;
  int _currentPage = 0;
  bool _hasNavigated = false;

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      // Clear any error state before navigating
      ref.read(addStoryNotifierProvider.notifier).resetErrorState();

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Helper method to perform the async API call for posting the story.
  Future<void> _postStory(StoryData story, WidgetRef ref) async {
    try {
      // The image should already be uploaded at this point, so we're just creating the story
      // with the previously uploaded image's URL that's stored in the state
      await ref.read(addStoryNotifierProvider.notifier).addStory(
            body: story.caption,
            location: story.location.isNotEmpty ? story.location : null,
            latitude: story.latitude,
            longitude: story.longitude,
            // We're not passing the thumbnail here since it should already be uploaded
            // and the stored thumbnailUrl will be used by the backend
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use ref.listen inside the build method (which is safe) instead of initState/didChangeDependencies.
    ref.listen<AddStoryState>(addStoryNotifierProvider, (previous, state) {
      if (state.isSuccess && !_hasNavigated) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const FeedScreen()),
            );
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Your Story',
          style: TextStyle(
            color: AppColor.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: const [
          SelectImageStep(),
          AddCaptionStep(),
          AddLocationStep(),
          PreviewStep(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColor.colorFAFBFF,
        child: Row(
          children: [
            if (_currentPage > 0) ...[
              Expanded(
                child: AppButton(
                  buttonType: ButtonType.secondary,
                  borderRadius: 32,
                  text: "Back",
                  onPressed: _goToPreviousPage,
                ),
              ),
              const SizedBox(width: 16),
            ] else
              const SizedBox(),
            if (_currentPage < _totalPages - 1)
              Expanded(
                child: AppButton(
                  isIconLeft: true,
                  text: "Next",
                  borderRadius: 32,
                  icon: const Icon(
                    Icons.arrow_forward_outlined,
                    color: Colors.white,
                  ),
                  onPressed: _goToNextPage,
                ),
              )
            else
              Consumer(
                builder: (context, ref, child) {
                  final story = ref.watch(storyProvider);
                  final addStoryState = ref.watch(addStoryNotifierProvider);
                  final VoidCallback? handlePost = addStoryState.isLoading
                      ? null
                      : () => _postStory(story, ref);
                  return Expanded(
                    child: AppButton(
                        borderRadius: 32,
                        text: addStoryState.isLoading ? "Posting..." : "Post",
                        isFullWidth: true,
                        onPressed: handlePost ?? () {}),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Step 1: Select an image
class SelectImageStep extends ConsumerWidget {
  const SelectImageStep({Key? key}) : super(key: key);

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Set the image in the provider
      final imageFile = File(pickedFile.path);
      ref.read(storyProvider.notifier).setImage(imageFile);

      // Only upload the image without posting the story
      try {
        await ref
            .read(addStoryNotifierProvider.notifier)
            .uploadImage(imageFile);
      } catch (e) {
        // Error will be shown in the UI via the AddStoryState
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyData = ref.watch(storyProvider);
    final addStoryState = ref.watch(addStoryNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          if (storyData.image != null)
            Stack(
              alignment: Alignment.center,
              children: [
                Image.file(
                  storyData.image!,
                  height: 400,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (addStoryState.isUploading)
                  Container(
                    height: 400,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Uploading image to AWS...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        CircularProgressIndicator(
                          value: addStoryState.uploadProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${((addStoryState.uploadProgress ?? 0.0) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                if (addStoryState.errorMessage != null)
                  Container(
                    height: 400,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Error: ${addStoryState.errorMessage}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        AppButton(
                          text: "Try Again",
                          onPressed: () => _pickImage(ref),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(child: Text('No image selected')),
            ),
          const SizedBox(height: 20),
          AppButton(
            text:
                storyData.image == null ? "Pick from Gallery" : "Change Image",
            onPressed:
                addStoryState.isUploading ? () {} : () => _pickImage(ref),
          ),
        ],
      ),
    );
  }
}

/// Step 2: Add a caption
class AddCaptionStep extends ConsumerWidget {
  const AddCaptionStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyData = ref.watch(storyProvider);
    final captionController = TextEditingController(text: storyData.caption);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (storyData.image != null)
            Image.file(
              storyData.image!,
              height: 320,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          const SizedBox(height: 24),
          const Text(
            'Add Caption',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 190,
            child: Directionality(
              textDirection:
                  TextDirection.rtl, // Ensure everything inside is LTR
              child: TextField(
                controller: captionController,
                textAlign: TextAlign.left,
                expands: true,
                maxLines: null,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: 'Write your caption here...',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: AppColor.colorABB0B9,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: AppColor.colorABB0B9,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: AppColor.black,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  ref.read(storyProvider.notifier).setCaption(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 4: Preview & Post
class PreviewStep extends ConsumerWidget {
  const PreviewStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyData = ref.watch(storyProvider);
    final addStoryState = ref.watch(addStoryNotifierProvider);

    // Get the repository to access the uploaded thumbnail URL
    final storyRepository = ref.watch(storyRepositoryProvider);
    final thumbnailUrl = storyRepository.uploadedThumbnailUrl;

    // Show error message if there's an error
    if (addStoryState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              'Error: ${addStoryState.errorMessage}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Show location details if available
          if (storyData.location.isNotEmpty || storyData.latitude != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppColor.black, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Location Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColor.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (storyData.location.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 28, bottom: 4),
                      child: Text(
                        storyData.location,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  if (storyData.latitude != null && storyData.longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(
                        'Coordinates: ${storyData.latitude!.toStringAsFixed(6)}, ${storyData.longitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          PostCard(
            contentId: 1,
            isOwner: true,
            profileImageUrl: 'https://picsum.photos/seed/profile100/200',
            name: 'User ',
            location: storyData.location,
            timeAgo: '1 hour ago',
            postImageUrl: thumbnailUrl ??
                (storyData.image != null
                    ? 'file://${storyData.image!.path}'
                    : 'https://picsum.photos/seed/post100/400'),
            headline: storyData.caption,
            likeCount: 7,
            commentCount: 5,
            isFollowing: true,
            repostCount: 7,
            onLike: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Liked!')),
              );
            },
            onComment: () {},
            onRepost: () {},
            onShare: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share clicked!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
