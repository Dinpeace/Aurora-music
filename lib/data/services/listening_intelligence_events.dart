import 'dart:async';

/// Application-wide signal emitted after Aurora changes local listening
/// intelligence.
///
/// The event carries no player state and no song payload. Consumers should
/// reload their own current history/profile state when notified. This keeps
/// the event bus lightweight and prevents stale recommendation data from
/// being passed around the application.
class ListeningIntelligenceEvents {
  ListeningIntelligenceEvents._();

  static final ListeningIntelligenceEvents instance =
      ListeningIntelligenceEvents._();

  final StreamController<void> _controller =
      StreamController<void>.broadcast();

  Stream<void> get changes => _controller.stream;

  void notifyChanged() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  Future<void> disposeForTests() async {
    await _controller.close();
  }
}
