import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuroraSearchBar extends StatelessWidget {
  const AuroraSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      onTap: () => context.push('/search'),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search songs, artists, albums...',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(
          Icons.search,
          color: Colors.white54,
        ),
        suffixIcon: const Icon(
          Icons.mic_none_rounded,
          color: Colors.white54,
        ),
        filled: true,
        fillColor: const Color(0xFF18181B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFA855F7),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
