import 'package:flutter/material.dart';

/// A smart image widget that automatically picks between Image.asset and
/// Image.network depending on the URL scheme. URLs that start with "assets/"
/// are loaded from bundled assets; everything else is treated as a network URL.
///
/// Provides built-in placeholder and error handling.
class SmartImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  bool get _isAsset => imageUrl.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildFallback();
    }

    Widget image;
    if (_isAsset) {
      image = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else {
      image = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.grey.shade400,
                  ),
                ),
              );
        },
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }
    return image;
  }

  Widget _buildFallback() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          child: Icon(
            Icons.image_outlined,
            size: (width ?? 48) * 0.4,
            color: Colors.grey.shade400,
          ),
        );
  }
}
