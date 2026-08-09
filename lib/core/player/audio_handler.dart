abstract class AudioHandler {
  Future<void> play(String source);

  Future<void> pause();

  Future<void> stop();

  Future<void> seek(Duration position);

  Future<void> skipNext();

  Future<void> skipPrevious();
}