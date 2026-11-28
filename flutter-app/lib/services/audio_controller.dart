import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../theme/elysion_theme.dart';
import 'api_service.dart';

class ElysionAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();
  VoidCallback? onNextRequested;
  VoidCallback? onPrevRequested;

  ElysionAudioHandler() {
    player.playbackEventStream.listen(_broadcastState);
    player.processingStateStream.listen((st) {
      if (st == ProcessingState.completed) {
        onNextRequested?.call();
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
    ));
  }

  Future<void> loadAndPlay(Track tr) async {
    mediaItem.add(MediaItem(
      id: tr.id,
      title: tr.title,
      artist: tr.artist,
      duration: tr.duration > 0 ? Duration(seconds: tr.duration) : null,
      artUri: tr.coverUrl.isNotEmpty ? Uri.tryParse(tr.coverUrl) : null,
    ));
    await player.setUrl(tr.streamUrl);
    await player.play();
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() async => onNextRequested?.call();

  @override
  Future<void> skipToPrevious() async => onPrevRequested?.call();
}

class ElysionAppController extends ChangeNotifier {
  final ElysionAudioHandler audioHandler;
  AudioPlayer get player => audioHandler.player;

  String? activeUser; // 'he' | 'she'
  String paletteId = 'violet-rose';
  String playerBgStyle = 'mesh'; // 'mesh' | 'silk' | 'bloom' | 'static'
  bool shuffle = false;
  bool repeatOne = false;
  bool isLoading = false;
  String? errorMessage;

  List<Track> tracks = [];
  List<ElysionPlaylist> playlists = [];
  Map<String, List<String>> playlistMap = {};
  Map<String, UserProfile> profiles = {};
  Map<String, int> localTrackPlays = {};
  List<String> recentSearches = [];
  final Map<String, LyricsData> lyricsCache = {};

  List<Track> queue = [];
  int currentIndex = -1;
  String playContextLabel = 'Вся коллекция';

  Track? get currentTrack => (currentIndex >= 0 && currentIndex < queue.length) ? queue[currentIndex] : null;
  ElysionPalette get palette => paletteById(paletteId);
  String get partnerId => activeUser == 'he' ? 'she' : 'he';

  ElysionAppController(this.audioHandler) {
    audioHandler.onNextRequested = () => nextTrack();
    audioHandler.onPrevRequested = () => prevTrack(forcePrev: false);
    player.playingStream.listen((_) => notifyListeners());
    player.positionStream.listen((pos) {
      final tr = currentTrack;
      if (tr != null && pos.inSeconds == 30) {
        _bumpTrackPlay(tr.id);
      }
    });
  }

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    final prefs = await SharedPreferences.getInstance();
    activeUser = prefs.getString('elysion_active_user');
    paletteId = prefs.getString('elysion_palette') ?? 'violet-rose';
    playerBgStyle = prefs.getString('elysion_player_bg') ?? 'mesh';
    recentSearches = prefs.getStringList('elysion_recent_searches') ?? [];
    final playsRaw = prefs.getString('elysion_track_plays');
    if (playsRaw != null) {
      try {
        final decoded = jsonDecode(playsRaw) as Map<String, dynamic>;
        decoded.forEach((k, v) { if (v is num) localTrackPlays[k] = v.toInt(); });
      } catch (_) {}
    }
    notifyListeners();
    await refreshCloud();
  }

  Future<void> selectUser(String userId) async {
    activeUser = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elysion_active_user', userId);
    notifyListeners();
  }

  Future<void> logoutUser() async {
    activeUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('elysion_active_user');
    notifyListeners();
  }

  Future<void> setPalette(String id) async {
    paletteId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elysion_palette', id);
    notifyListeners();
  }

  Future<void> setPlayerBgStyle(String style) async {
    playerBgStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elysion_player_bg', style);
    notifyListeners();
  }

  Future<void> addRecentSearch(String term) async {
    final clean = term.trim();
    if (clean.length < 2) return;
    recentSearches.removeWhere((e) => e.toLowerCase() == clean.toLowerCase());
    recentSearches.insert(0, clean);
    if (recentSearches.length > 10) recentSearches = recentSearches.sublist(0, 10);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('elysion_recent_searches', recentSearches);
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    recentSearches.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('elysion_recent_searches');
    notifyListeners();
  }

  Future<void> refreshCloud() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        ElysionApi.fetchTracks(),
        ElysionApi.fetchPlaylists(),
        ElysionApi.fetchPlaylistTracks(),
        ElysionApi.fetchProfiles(),
      ]);
      tracks = results[0] as List<Track>;
      playlists = results[1] as List<ElysionPlaylist>;
      playlistMap = results[2] as Map<String, List<String>>;
      profiles = results[3] as Map<String, UserProfile>;

      // Restore last played track silently (paused) if present — NEVER auto-pick newest track!
      if (currentTrack == null && tracks.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastId = prefs.getString('elysion_last_track_id');
        if (lastId != null) {
          final idx = tracks.indexWhere((t) => t.id == lastId);
          if (idx >= 0) {
            queue = List<Track>.from(tracks);
            currentIndex = idx;
          }
        }
      }
    } catch (e) {
      errorMessage = 'Не удалось загрузить библиотеку';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _bumpTrackPlay(String trackId) async {
    localTrackPlays[trackId] = (localTrackPlays[trackId] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elysion_track_plays', jsonEncode(localTrackPlays));
  }

  Future<void> playTrack(Track track, {List<Track>? customQueue, String? contextLabel}) async {
    final list = (customQueue != null && customQueue.isNotEmpty) ? List<Track>.from(customQueue) : List<Track>.from(tracks);
    final idx = list.indexWhere((t) => t.id == track.id);
    queue = list;
    currentIndex = idx >= 0 ? idx : 0;
    if (contextLabel != null) playContextLabel = contextLabel;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elysion_last_track_id', track.id);
    try {
      await audioHandler.loadAndPlay(queue[currentIndex]);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (currentTrack == null) return;
    if (player.playing) {
      await audioHandler.pause();
    } else {
      if (player.processingState == ProcessingState.idle) {
        await audioHandler.loadAndPlay(currentTrack!);
      } else {
        await audioHandler.play();
      }
    }
    notifyListeners();
  }

  Future<void> nextTrack() async {
    if (queue.isEmpty) return;
    if (repeatOne && currentTrack != null) {
      await player.seek(Duration.zero);
      await player.play();
      return;
    }
    if (shuffle && queue.length > 1) {
      final rnd = Random();
      int nextIdx = currentIndex;
      while (nextIdx == currentIndex) {
        nextIdx = rnd.nextInt(queue.length);
      }
      currentIndex = nextIdx;
    } else {
      currentIndex = (currentIndex + 1) % queue.length;
    }
    final tr = queue[currentIndex];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elysion_last_track_id', tr.id);
    try {
      await audioHandler.loadAndPlay(tr);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> prevTrack({bool forcePrev = false}) async {
    if (queue.isEmpty) return;
    if (!forcePrev && player.position.inSeconds > 3) {
      await player.seek(Duration.zero);
      return;
    }
    currentIndex = (currentIndex - 1 + queue.length) % queue.length;
    final tr = queue[currentIndex];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elysion_last_track_id', tr.id);
    try {
      await audioHandler.loadAndPlay(tr);
    } catch (_) {}
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    repeatOne = !repeatOne;
    notifyListeners();
  }

  Future<void> toggleLike(Track track) async {
    final u = activeUser ?? 'he';
    final nextVal = !track.isLikedBy(u);
    if (u == 'he') {
      track.likedHe = nextVal;
    } else {
      track.likedShe = nextVal;
    }
    notifyListeners();
    try {
      await ElysionApi.updateTrackLike(track.id, u, nextVal);
    } catch (_) {}
  }

  Future<LyricsData> getLyrics(Track track) async {
    if (lyricsCache.containsKey(track.id)) return lyricsCache[track.id]!;
    final data = await ElysionApi.fetchLyrics(track);
    lyricsCache[track.id] = data;
    return data;
  }

  List<Track> getSmartPlaylist(String id) {
    final u = activeUser ?? 'he';
    if (id == 'matches') return tracks.where((t) => t.isMatch).toList();
    if (id == 'my-likes') return tracks.where((t) => t.isLikedBy(u)).toList();
    if (id == 'partner-taste') return tracks.where((t) => t.isLikedBy(partnerId) && !t.isLikedBy(u)).toList();
    if (id == 'all') return List<Track>.from(tracks);
    final ids = playlistMap[id] ?? [];
    final byId = {for (final t in tracks) t.id: t};
    return ids.map((tid) => byId[tid]).whereType<Track>().toList();
  }

  List<ArtistSummary> getArtistsSummary() {
    final u = activeUser ?? 'he';
    final secMap = profiles[u]?.artistSec ?? {};
    final counts = <String, int>{};
    final covers = <String, String>{};
    final canonical = <String, String>{};
    for (final t in tracks) {
      for (final a in t.artistsList) {
        final k = a.toLowerCase();
        canonical.putIfAbsent(k, () => a);
        counts[k] = (counts[k] ?? 0) + 1;
        if (!covers.containsKey(k) && t.coverUrl.isNotEmpty) covers[k] = t.coverUrl;
      }
    }
    final list = canonical.entries.map((e) {
      final name = e.value;
      return ArtistSummary(
        name: name,
        trackCount: counts[e.key] ?? 0,
        listenSec: secMap[name] ?? 0,
        coverUrl: covers[e.key] ?? '',
      );
    }).toList();
    list.sort((a, b) => b.listenSec != a.listenSec ? b.listenSec.compareTo(a.listenSec) : b.trackCount.compareTo(a.trackCount));
    return list;
  }

  List<Track> getArtistTracks(String artistName) {
    final nl = artistName.toLowerCase();
    return tracks.where((t) => t.artistsList.any((a) => a.toLowerCase() == nl) || t.artist.toLowerCase().contains(nl)).toList();
  }
}
