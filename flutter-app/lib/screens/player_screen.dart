import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/audio_controller.dart';
import '../theme/elysion_theme.dart';
import '../widgets/elysion_brand.dart';
import '../widgets/mesh_background.dart';
import 'artist_screen.dart';

class FullPlayerSheet extends StatefulWidget {
  final ElysionAppController ctrl;
  const FullPlayerSheet({super.key, required this.ctrl});

  @override
  State<FullPlayerSheet> createState() => _FullPlayerSheetState();
}

class _FullPlayerSheetState extends State<FullPlayerSheet> {
  String _mode = 'cover'; // 'cover' | 'lyrics' | 'queue'
  LyricsData? _lyrics;
  String? _lyricsForId;
  bool _loadingLyrics = false;
  final ScrollController _lyricsScroll = ScrollController();
  int _lastActiveIdx = -1;
  DateTime _manualScrollPauseUntil = DateTime.fromMillisecondsSinceEpoch(0);
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onCtrlUpdate);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onCtrlUpdate);
    _lyricsScroll.dispose();
    super.dispose();
  }

  void _onCtrlUpdate() {
    if (!mounted) return;
    final tr = widget.ctrl.currentTrack;
    if (_mode == 'lyrics' && tr != null && tr.id != _lyricsForId) {
      _loadLyrics(tr);
    }
    setState(() {});
  }

  Future<void> _loadLyrics(Track tr) async {
    _lyricsForId = tr.id;
    _lastActiveIdx = -1;
    setState(() => _loadingLyrics = true);
    final data = await widget.ctrl.getLyrics(tr);
    if (mounted && _lyricsForId == tr.id) {
      setState(() {
        _lyrics = data;
        _loadingLyrics = false;
      });
    }
  }

  String _fmt(Duration d) {
    final s = d.inSeconds.clamp(0, 36000);
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final tr = ctrl.currentTrack;
    final pal = ctrl.palette;
    final user = ctrl.activeUser ?? 'he';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: NativeMeshBackground(
              mode: ctrl.playerBgStyle,
              c1: pal.c1,
              c2: pal.c2,
              c3: pal.c3,
              dimmed: _mode == 'lyrics',
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Column(
                children: [
                  // Header
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: cAlpha(Colors.white, 0.22), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('СЕЙЧАС ИГРАЕТ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: cAlpha(Colors.white, 0.55))),
                            const SizedBox(height: 2),
                            Text(ctrl.playContextLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  // Center stage: Cover / Lyrics / Queue
                  Expanded(
                    child: tr == null
                        ? const Center(child: Text('Нет активного трека', style: TextStyle(color: Colors.white54)))
                        : _mode == 'lyrics'
                            ? _buildLyricsStage(tr)
                            : _mode == 'queue'
                                ? _buildQueueStage(ctrl)
                                : _buildCoverStage(tr),
                  ),

                  // Title + Artist + Dual Hearts
                  if (tr != null && _mode == 'cover') ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                              const SizedBox(height: 3),
                              GestureDetector(
                                onTap: () {
                                  final firstArtist = tr.artistsList.isNotEmpty ? tr.artistsList.first : tr.artist;
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArtistScreen(ctrl: ctrl, artistName: firstArtist)));
                                },
                                child: Text(tr.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: cAlpha(Colors.white, 0.65))),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ctrl.toggleLike(tr);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: cAlpha(Colors.white, 0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: cAlpha(Colors.white, 0.14)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite_rounded, size: 17, color: tr.likedHe ? const Color(0xFFA855F7) : cAlpha(Colors.white, 0.25)),
                                const SizedBox(width: 6),
                                Icon(Icons.favorite_rounded, size: 17, color: tr.likedShe ? const Color(0xFFEC4899) : cAlpha(Colors.white, 0.25)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Progress scrubber
                  StreamBuilder<Duration>(
                    stream: ctrl.player.positionStream,
                    builder: (_, snap) {
                      final pos = snap.data ?? Duration.zero;
                      final dur = ctrl.player.duration ?? Duration(seconds: tr?.duration ?? 0);
                      final maxMs = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
                      final curMs = pos.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();
                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: cAlpha(Colors.white, 0.22),
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: curMs,
                              min: 0,
                              max: maxMs,
                              onChanged: (v) => ctrl.player.seek(Duration(milliseconds: v.round())),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(pos), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cAlpha(Colors.white, 0.55))),
                                Text(_fmt(dur), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cAlpha(Colors.white, 0.55))),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Playback controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: ctrl.toggleRepeat,
                        icon: Icon(Icons.repeat_rounded, color: ctrl.repeatOne ? pal.c2 : cAlpha(Colors.white, 0.55)),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ctrl.prevTrack(forcePrev: false);
                        },
                        icon: const Icon(Icons.skip_previous_rounded, size: 36, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ctrl.togglePlay();
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(ctrl.player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 38, color: kBgDark),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ctrl.nextTrack();
                        },
                        icon: const Icon(Icons.skip_next_rounded, size: 36, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: ctrl.toggleShuffle,
                        icon: Icon(Icons.shuffle_rounded, color: ctrl.shuffle ? pal.c2 : cAlpha(Colors.white, 0.55)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bottom action dock (Lyrics, Queue, Like)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _modeBtn(Icons.lyrics_rounded, _mode == 'lyrics', () {
                        setState(() => _mode = _mode == 'lyrics' ? 'cover' : 'lyrics');
                        if (_mode == 'lyrics' && tr != null) _loadLyrics(tr);
                      }),
                      _modeBtn(Icons.queue_music_rounded, _mode == 'queue', () {
                        setState(() => _mode = _mode == 'queue' ? 'cover' : 'queue');
                      }),
                      _modeBtn(
                        (tr != null && tr.isLikedBy(user)) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        tr != null && tr.isLikedBy(user),
                        () { if (tr != null) ctrl.toggleLike(tr); },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeBtn(IconData icon, bool active, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? cAlpha(Colors.white, 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 22, color: active ? Colors.white : cAlpha(Colors.white, 0.58)),
      ),
    );
  }

  Widget _buildCoverStage(Track tr) {
    final coverSize = (MediaQuery.of(context).size.width - 56).clamp(240.0, 340.0);
    return GestureDetector(
      onHorizontalDragUpdate: (d) => setState(() => _dragDx = (_dragDx + d.delta.dx).clamp(-110.0, 110.0)),
      onHorizontalDragEnd: (_) {
        if (_dragDx < -52) {
          HapticFeedback.lightImpact();
          widget.ctrl.nextTrack();
        } else if (_dragDx > 52) {
          HapticFeedback.lightImpact();
          widget.ctrl.prevTrack(forcePrev: true);
        }
        setState(() => _dragDx = 0);
      },
      child: Center(
        child: AnimatedContainer(
          duration: _dragDx == 0 ? const Duration(milliseconds: 240) : Duration.zero,
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(_dragDx * 0.7, 0, 0),
          child: TrackCover(url: tr.coverUrl, size: coverSize, radius: 28),
        ),
      ),
    );
  }

  Widget _buildLyricsStage(Track tr) {
    if (_loadingLyrics) {
      return const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2));
    }
    final lyr = _lyrics;
    if (lyr == null || lyr.isEmpty) {
      return Center(child: Text('Текст для этого трека пока не найден', style: TextStyle(color: cAlpha(Colors.white, 0.5))));
    }
    if (lyr.synced.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(lyr.plain, style: TextStyle(fontSize: 19, height: 1.5, fontWeight: FontWeight.w600, color: cAlpha(Colors.white, 0.8))),
      );
    }
    return StreamBuilder<Duration>(
      stream: widget.ctrl.player.positionStream,
      builder: (_, snap) {
        final pos = (snap.data ?? Duration.zero) + Duration(milliseconds: (tr.lyricOffset * 1000).round() + 150);
        int activeIdx = -1;
        for (int i = 0; i < lyr.synced.length; i++) {
          if (pos >= lyr.synced[i].time) activeIdx = i; else break;
        }
        if (activeIdx != _lastActiveIdx && activeIdx >= 0) {
          _lastActiveIdx = activeIdx;
          if (DateTime.now().isAfter(_manualScrollPauseUntil) && _lyricsScroll.hasClients) {
            final target = (activeIdx * 62.0 - 120.0).clamp(0.0, _lyricsScroll.position.maxScrollExtent);
            _lyricsScroll.animateTo(target, duration: const Duration(milliseconds: 460), curve: Curves.easeOutCubic);
          }
        }
        return NotificationListener<ScrollStartNotification>(
          onNotification: (n) {
            if (n.dragDetails != null) _manualScrollPauseUntil = DateTime.now().add(const Duration(seconds: 3));
            return false;
          },
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.12, 0.85, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              controller: _lyricsScroll,
              padding: const EdgeInsets.symmetric(vertical: 48),
              itemCount: lyr.synced.length,
              itemBuilder: (_, i) {
                final line = lyr.synced[i];
                final active = i == activeIdx;
                final past = i < activeIdx;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.ctrl.player.seek(line.time);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 340),
                      opacity: active ? 1.0 : (past ? 0.28 : 0.40),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.centerLeft,
                        scale: active ? 1.03 : 0.985,
                        child: Text(
                          line.text,
                          style: const TextStyle(fontSize: 22, height: 1.32, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueueStage(ElysionAppController ctrl) {
    final user = ctrl.activeUser ?? 'he';
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: ctrl.queue.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = ctrl.queue[i];
        return TrackRowTile(
          track: t,
          activeUser: user,
          isPlaying: i == ctrl.currentIndex,
          accentColor: ctrl.palette.c2,
          onTap: () => ctrl.playTrack(t, customQueue: ctrl.queue, contextLabel: ctrl.playContextLabel),
          onLike: () => ctrl.toggleLike(t),
        );
      },
    );
  }
}
