import '../../models/online/online_song.dart';
import 'models/album_response.dart';
import 'models/artist_response.dart';
import 'models/search_response.dart';
import 'models/stream_response.dart';

abstract class MusicProvider {
  Future<SearchResponse> search(String query);

  Future<List<OnlineSong>> getTrending();

  Future<List<AlbumResponse>> getAlbums();

  Future<List<ArtistResponse>> getArtists();

  Future<StreamResponse> getStream(String songId);
}
