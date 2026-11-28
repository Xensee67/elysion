const String kSupabaseUrl = 'https://kotaahqgtupoortjpcqx.supabase.co';
const String kSupabaseKey = 'sb_publishable_pMXNz60PjUxhYk9uuX1AOw_qBDa3IDQ';
const String kWorkerUrl = 'https://elysion-api.romanace221.workers.dev';

class Track {
  final String id;
  final String title;
  final String artist;
  final String sourceRef;
  final String? rawCoverUrl;
  final String addedBy;
  bool likedHe;
  bool likedShe;
  final int duration;
  final String? mood;
  final String? noteText;
  final double lyricOffset;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.sourceRef,
    this.rawCoverUrl,
    required this.addedBy,
    required this.likedHe,
    required this.likedShe,
    required this.duration,
    this.mood,
    this.noteText,
    this.lyricOffset = 0,
  });

  String get streamUrl => '$kWorkerUrl/stream/$sourceRef';

  String get coverUrl {
    final c = (rawCoverUrl ?? '').trim();
    if (c.isEmpty) return '';
    if (c.startsWith('http://') || c.startsWith('https://')) return c;
    return '$kWorkerUrl/cover/$c';
  }

  bool isLikedBy(String user) => user == 'he' ? likedHe : likedShe;
  bool get isMatch => likedHe && likedShe;

  List<String> get artistsList => artist
      .split(RegExp(r',|&|feat\.?|ft\.?', caseSensitive: false))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        id: j['id'].toString(),
        title: (j['title'] ?? 'Без названия').toString(),
        artist: (j['artist'] ?? 'Неизвестный').toString(),
        sourceRef: (j['source_ref'] ?? '').toString(),
        rawCoverUrl: j['cover_url']?.toString(),
        addedBy: (j['added_by'] ?? 'he').toString(),
        likedHe: j['like_he'] == true,
        likedShe: j['like_she'] == true,
        duration: (j['duration'] is num) ? (j['duration'] as num).toInt() : 0,
        mood: j['mood']?.toString(),
        noteText: j['note_text']?.toString(),
        lyricOffset: (j['lyric_offset'] is num) ? (j['lyric_offset'] as num).toDouble() : 0.0,
      );
}

class ElysionPlaylist {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final String? coverUrl;

  ElysionPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    this.coverUrl,
  });

  factory ElysionPlaylist.fromJson(Map<String, dynamic> j) => ElysionPlaylist(
        id: j['id'].toString(),
        name: (j['name'] ?? 'Плейлист').toString(),
        description: (j['description'] ?? '').toString(),
        createdBy: (j['created_by'] ?? 'he').toString(),
        coverUrl: j['cover_url']?.toString(),
      );
}

class UserProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bannerUrl;
  final String statusText;
  final String? pinnedTrackId;
  final int totalPlays;
  final Map<String, int> artistSec;

  UserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bannerUrl,
    required this.statusText,
    this.pinnedTrackId,
    required this.totalPlays,
    required this.artistSec,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    final rawSec = j['artist_sec'];
    final secMap = <String, int>{};
    if (rawSec is Map) {
      rawSec.forEach((k, v) {
        if (v is num) secMap[k.toString()] = v.toInt();
      });
    }
    return UserProfile(
      id: (j['id'] ?? 'he').toString(),
      name: (j['name'] ?? (j['id'] == 'she' ? 'Маша' : 'Рома')).toString(),
      avatarUrl: j['avatar_url']?.toString(),
      bannerUrl: j['banner_url']?.toString(),
      statusText: (j['status_text'] ?? '').toString(),
      pinnedTrackId: j['pinned_track_id']?.toString(),
      totalPlays: (j['total_plays'] is num) ? (j['total_plays'] as num).toInt() : 0,
      artistSec: secMap,
    );
  }
}

class LyricLine {
  final Duration time;
  final String text;
  const LyricLine(this.time, this.text);
}

class LyricsData {
  final List<LyricLine> synced;
  final String plain;
  const LyricsData({required this.synced, required this.plain});
  bool get isEmpty => synced.isEmpty && plain.trim().isEmpty;
}

class ArtistSummary {
  final String name;
  final int trackCount;
  final int listenSec;
  final String coverUrl;
  const ArtistSummary({
    required this.name,
    required this.trackCount,
    required this.listenSec,
    required this.coverUrl,
  });
}
