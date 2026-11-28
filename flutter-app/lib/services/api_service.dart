import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ElysionApi {
  static Map<String, String> get _headers => {
        'apikey': kSupabaseKey,
        'Authorization': 'Bearer $kSupabaseKey',
        'Content-Type': 'application/json',
      };

  static Future<List<Track>> fetchTracks() async {
    final uri = Uri.parse('$kSupabaseUrl/rest/v1/tracks?select=*&order=id.desc');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('Tracks HTTP ${res.statusCode}');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<ElysionPlaylist>> fetchPlaylists() async {
    final uri = Uri.parse('$kSupabaseUrl/rest/v1/playlists?select=*&order=id.asc');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => ElysionPlaylist.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, List<String>>> fetchPlaylistTracks() async {
    final uri = Uri.parse('$kSupabaseUrl/rest/v1/playlist_tracks?select=playlist_id,track_id,position&order=position.asc');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return {};
    final list = jsonDecode(res.body) as List<dynamic>;
    final map = <String, List<String>>{};
    for (final item in list) {
      final pid = item['playlist_id'].toString();
      final tid = item['track_id'].toString();
      map.putIfAbsent(pid, () => []).add(tid);
    }
    return map;
  }

  static Future<Map<String, UserProfile>> fetchProfiles() async {
    final uri = Uri.parse('$kSupabaseUrl/rest/v1/profiles?select=*');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return {};
    final list = jsonDecode(res.body) as List<dynamic>;
    final map = <String, UserProfile>{};
    for (final item in list) {
      final p = UserProfile.fromJson(item as Map<String, dynamic>);
      map[p.id] = p;
    }
    return map;
  }

  static Future<void> updateTrackLike(String trackId, String user, bool liked) async {
    final col = user == 'he' ? 'like_he' : 'like_she';
    final uri = Uri.parse('$kSupabaseUrl/rest/v1/tracks?id=eq.$trackId');
    await http.patch(uri, headers: _headers, body: jsonEncode({col: liked}));
  }

  static Future<void> updateProfileFields(String userId, Map<String, dynamic> fields) async {
    final uri = Uri.parse('$kSupabaseUrl/rest/v1/profiles?id=eq.$userId');
    await http.patch(uri, headers: _headers, body: jsonEncode(fields));
  }

  static List<LyricLine> _parseLrc(String lrc) {
    final lines = <LyricLine>[];
    final rx = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)');
    for (final raw in lrc.split('
')) {
      final m = rx.firstMatch(raw.trim());
      if (m != null) {
        final mins = int.tryParse(m.group(1) ?? '0') ?? 0;
        final secs = double.tryParse(m.group(2) ?? '0') ?? 0.0;
        final txt = (m.group(3) ?? '').trim();
        if (txt.isNotEmpty) {
          lines.add(LyricLine(Duration(milliseconds: ((mins * 60 + secs) * 1000).round()), txt));
        }
      }
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  static Future<LyricsData> fetchLyrics(Track track) async {
    try {
      final cleanArtist = track.artistsList.isNotEmpty ? track.artistsList.first : track.artist;
      final q = Uri.encodeQueryComponent('$cleanArtist ${track.title}');
      final uri = Uri.parse('https://lrclib.net/api/search?q=$q');
      final res = await http.get(uri).timeout(const Duration(seconds: 7));
      if (res.statusCode == 200) {
        final arr = jsonDecode(res.body) as List<dynamic>;
        if (arr.isNotEmpty) {
          final best = arr.firstWhere(
            (e) => (e['syncedLyrics'] ?? '').toString().trim().isNotEmpty,
            orElse: () => arr.first,
          );
          final syncedStr = (best['syncedLyrics'] ?? '').toString();
          final plainStr = (best['plainLyrics'] ?? '').toString();
          return LyricsData(
            synced: syncedStr.isNotEmpty ? _parseLrc(syncedStr) : [],
            plain: plainStr,
          );
        }
      }
    } catch (_) {}
    return const LyricsData(synced: [], plain: '');
  }
}
