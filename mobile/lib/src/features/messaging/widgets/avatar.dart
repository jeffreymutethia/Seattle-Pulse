import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool isOnline;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color onlineIndicatorColor;

  const Avatar({
    super.key,
    this.imageUrl,
    this.size = 40.0,
    this.isOnline = false,
    this.borderColor,
    this.backgroundColor,
    this.onlineIndicatorColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor ?? Colors.grey[300],
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 2.0)
                : null,
          ),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        _buildFallbackAvatar(),
                    placeholder: (context, url) => _buildFallbackAvatar(),
                  ),
                )
              : _buildFallbackAvatar(),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: onlineIndicatorColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return Center(
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }
}
