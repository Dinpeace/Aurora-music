class Endpoints {
  const Endpoints._();

  /// Configure the online provider without hard-coding its URL in the app:
  ///
  /// flutter run --dart-define=AURORA_API_BASE_URL=https://example.com
  static const String baseUrl = String.fromEnvironment(
    'AURORA_API_BASE_URL',
    defaultValue: '',
  );

  static const String search = '/search';
  static const String trending = '/trending';
  static const String song = '/song';
  static const String albums = '/albums';
  static const String artists = '/artists';
}
