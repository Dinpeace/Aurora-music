import 'package:flutter/services.dart';

class MediaChannel {
  MediaChannel._();

  static const MethodChannel _channel =
      MethodChannel('aurora_music/media');

  static Future<bool> requestPermission() async {
    final result =
        await _channel.invokeMethod<bool>('requestPermission');

    return result ?? false;
  }

  static Future<List<Map<String, dynamic>>> getSongs() async {
    final result =
        await _channel.invokeListMethod<dynamic>('getSongs');

    if (result == null) {
      return [];
    }

    return result
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}