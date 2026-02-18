// profile_tabs.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileTabsWidget extends StatelessWidget {
  final List<String> postImages;
  final List<String> repostImages;

  const ProfileTabsWidget({
    Key? key,
    required this.postImages,
    required this.repostImages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab Bar Section
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xffF1F4F9),
                  width: 2,
                ),
              ),
            ),
            child: TabBar(
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              dividerColor: Colors.transparent,
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicator:
                  const FullWidthIndicator(color: Colors.black, height: 3),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/icons/feed.png",
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      const Text("Posts"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/icons/reposted.png",
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      const Text("Reposts"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/icons/location.png",
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      const Text("Location"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab Bar View
          Expanded(
            child: TabBarView(
              children: [
                // Posts Tab
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                  child: _buildGridOfImages(postImages),
                ),
                // Reposts Tab
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildGridOfImages(repostImages),
                ),
                // Location Tab (unchanged)
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 8.0),
                    height: 400,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Image.asset(
                      "assets/images/location.png",
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a 3-column grid of images using CachedNetworkImage.
  Widget _buildGridOfImages(List<String> images) {
    if (images.isEmpty) {
      return const Center(child: Text("No images available"));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: images[index],
          height: 106,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 106,
            color: const Color.fromARGB(255, 214, 214, 214),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.error, color: Colors.red),
        );
      },
    );
  }
}

/// A custom full-width tab indicator positioned above the tab text.
class FullWidthIndicator extends Decoration {
  final Color color;
  final double height;

  const FullWidthIndicator({required this.color, required this.height});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _FullWidthPainter(color: color, height: height);
  }
}

class _FullWidthPainter extends BoxPainter {
  final Color color;
  final double height;

  _FullWidthPainter({required this.color, required this.height});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final Paint paint = Paint()..color = color;
    final double width = cfg.size!.width;
    final double xPos = offset.dx;
    final double yPos = offset.dy + cfg.size!.height - height;
    canvas.drawRect(Rect.fromLTWH(xPos, yPos, width, height), paint);
  }
}
