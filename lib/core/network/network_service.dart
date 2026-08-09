abstract class NetworkService {
  Future<dynamic> get(
    String path,
  );

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
  });
}