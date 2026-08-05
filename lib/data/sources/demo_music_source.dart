import '../models/song.dart';

class DemoMusicSource {
  DemoMusicSource._();

  static const List<Song> recentlyPlayed = [
    Song(
      id: '1',
      title: 'Aurora Vibes',
      artist: 'Aurora Studio',
      album: 'Aurora',
      artwork: 'assets/logos/aurora_logo.png',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      duration: Duration(minutes: 3, seconds: 42),
    ),
    Song(
      id: '2',
      title: 'Night Drive',
      artist: 'Synth Dreams',
      album: 'Midnight',
      artwork: 'assets/logos/aurora_logo.png',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      duration: Duration(minutes: 4, seconds: 8),
    ),
    Song(
      id: '3',
      title: 'Moonlight',
      artist: 'Aurora Studio',
      album: 'Sky',
      artwork: 'assets/logos/aurora_logo.png',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      duration: Duration(minutes: 3, seconds: 15),
    ),
  ];

  static const List<Song> trending = [
    Song(
      id: '4',
      title: 'Galaxy',
      artist: 'Nova',
      album: 'Universe',
      artwork: 'assets/logos/aurora_logo.png',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      duration: Duration(minutes: 3, seconds: 52),
    ),
    Song(
      id: '5',
      title: 'Sunrise',
      artist: 'Aurora Music',
      album: 'Morning',
      artwork: 'assets/logos/aurora_logo.png',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      duration: Duration(minutes: 4),
    ),
  ];

  static const List<Song> newReleases = [
    Song(
      id: '6',
      title: 'Dreamscape',
      artist: 'Aurora Originals',
      album: 'Dreams',
      artwork: 'assets/logos/aurora_logo.png',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
      duration: Duration(minutes: 3, seconds: 30),
    ),
    Song(
      id: '7',
      title: 'Beyond',
      artist: 'Aurora Originals',
      album: 'Infinity',
      artwork: 'assets/logos/aurora_logo.png',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
      duration: Duration(minutes: 4, seconds: 5),
    ),
  ];
}