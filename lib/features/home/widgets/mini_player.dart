import 'package:flutter/material.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        border: Border(
          top: BorderSide(
            color: Colors.white10,
          ),
        ),
      ),
      child: const ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFFA855F7),
          child: Icon(
            Icons.music_note,
            color: Colors.white,
          ),
        ),
        title: Text(
          "Nothing Playing",
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "Aurora Music",
          style: TextStyle(color: Colors.white70),
        ),
        trailing: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}