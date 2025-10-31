import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double radius;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackText,
    this.radius = 50,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidImage = imageUrl != null && 
                         imageUrl!.isNotEmpty &&
                         Uri.tryParse(imageUrl!)?.hasAbsolutePath == true;

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: hasValidImage
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    print('Image load error for $url: $error');
                    return _buildFallbackAvatar(context);
                  },
                ),
              )
            : _buildFallbackAvatar(context),
      ),
    );
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
