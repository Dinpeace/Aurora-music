import 'package:flutter/services.dart';

class MediaChannel {
  MediaChannel._();

  static const MethodChannel _channel =
      MethodChannel('aurora_music/media');

  static Future<bool> requestPermission() async {
    return await _channel.invokeMethod<bool>(
          'requestPermission',
        ) ??
        false;
  }

  static Future<List<Map<String, dynamic>>> getSongs() async {
    final result =
        await _channel.invokeMethod<List<dynamic>>(
      'getSongs',
    );

    if (result == null) {
      return [];
    }

    return result
        .map(
          (song) => Map<String, dynamic>.from(song),
        )
        .toList();
  }
}