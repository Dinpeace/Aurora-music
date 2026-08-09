import 'package:flutter/material.dart';

class ArtworkWidget extends StatelessWidget {
  final String? artwork;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ArtworkWidget({
    super.key,
    required this.artwork,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final hasArtwork =
        artwork != null &&
        artwork!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius:
          borderRadius ?? BorderRadius.circular(16),
      child: hasArtwork
          ? _placeholderArtwork()
          : _placeholderArtwork(),
    );
  }

  Widget _placeholderArtwork() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFA855F7),
            Color(0xFF22D3EE),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          color: Colors.white,
          size: 56,
        ),
      ),
    );
  }
}