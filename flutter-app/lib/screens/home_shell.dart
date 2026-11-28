import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/audio_controller.dart';
import '../theme/elysion_theme.dart';
import '../widgets/elysion_brand.dart';
import 'artist_screen.dart';
import 'player_screen.dart';
import 'playlist_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  final ElysionAppController ctrl;
  const HomeShell({super.key, required this.ctrl});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0; // 0: Библиотека, 1: Поиск, 2: Профиль
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openPlayer() {
    if (widget.ctrl.currentTrack == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => FullPlayerSheet(ctrl: widget.ctrl),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final pal = ctrl.palette;
        final cur = ctrl.currentTrack;
        final userName = ctrl.activeUser == 'she' ? 'Маша' : 'Рома';

        return Scaffold(
          backgroundColor: kBgDark,
          body: Stack(
            children: [
              // Subtle ambient top glow
              Positioned(
                top: -120,
                left: -80,
                right: -80,
                height: 360,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 0.9,
                        colors: [cAlpha(pal.c1, 0.24), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),

              IndexedStack(
                index: _tab,
                children: [
                  _buildLibraryTab(ctrl),
                  _buildSearchTab(ctrl),
                  _buildProfileTab(ctrl),
                ],
              ),

              // Floating Mini-Player + Bottom Nav Dock
              Positioned(
                left: 12,
                right: 12,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cur != null) _buildMiniPlayer(ctrl, cur, pal),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xEB0E0A1A),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: cAlpha(Colors.white, 0.11)),
                        ),
                        child: Row(
                          children: [
                            _navItem(0, Icons.library_music_rounded, 'Библиотека', pal),
                            _navItem(1, Icons.search_rounded, 'Поиск', pal),
                            _navItem(2, Icons.person_rounded, userName, pal),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navItem(int idx, IconData icon, String label, ElysionPalette pal) {
    final active = _tab == idx;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _tab = idx);
        },
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? cAlpha(pal.c2, 0.20) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21, color: active ? pal.c2 : cAlpha(Colors.white, 0.55)),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? Colors.white : cAlpha(Colors.white, 0.55))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(ElysionAppController ctrl, Track cur, ElysionPalette pal) {
    final user = ctrl.activeUser ?? 'he';
    return GestureDetector(
      onTap: _openPlayer,
      onHorizontalDragEnd: (d) {
        final vx = d.primaryVelocity ?? 0;
        if (vx < -200) ctrl.nextTrack();
        if (vx > 200) ctrl.prevTrack(forcePrev: true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xF0140E24),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cAlpha(Colors.white, 0.14)),
        ),
        child: Row(
          children: [
            TrackCover(url: cur.coverUrl, size: 42, radius: 11),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cur.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(cur.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: cAlpha(Colors.white, 0.58))),
                ],
              ),
            ),
            IconButton(
              onPressed: () => ctrl.toggleLike(cur),
              icon: Icon(cur.isLikedBy(user) ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20, color: cur.isLikedBy(user) ? pal.c2 : cAlpha(Colors.white, 0.45)),
            ),
            GestureDetector(
              onTap: ctrl.togglePlay,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(ctrl.player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 22, color: kBgDark),
              ),
            ),
            IconButton(
              onPressed: ctrl.nextTrack,
              icon: const Icon(Icons.skip_next_rounded, size: 24, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryTab(ElysionAppController ctrl) {
    final user = ctrl.activeUser ?? 'he';
    final pal = ctrl.palette;
    final partnerName = ctrl.partnerId == 'he' ? 'Ромы' : 'Маши';
    final smartCards = [
      ('matches', 'Наши совпадения', '${ctrl.getSmartPlaylist('matches').length} треков', [pal.c1, pal.c2]),
      ('partner-taste', 'Вкус $partnerName', '${ctrl.getSmartPlaylist('partner-taste').length} открытий', [const Color(0xFF7C3AED), const Color(0xFFEC4899)]),
      ('my-likes', 'Мне нравится', '${ctrl.getSmartPlaylist('my-likes').length} треков', [pal.c2, pal.c3]),
      ('all', 'Вся коллекция', '${ctrl.tracks.length} треков', [const Color(0xFF334155), const Color(0xFF0F172A)]),
    ];

    return RefreshIndicator(
      onRefresh: ctrl.refreshCloud,
      color: pal.c2,
      child: CustomScrollView(
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Библиотека', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                        IconButton(
                          onPressed: ctrl.refreshCloud,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.85),
                      itemCount: smartCards.length,
                      itemBuilder: (_, i) {
                        final item = smartCards[i];
                        return InkWell(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaylistDetailScreen(ctrl: ctrl, playlistId: item.$1, title: item.$2))),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cAlpha(item.$4[0], 0.55), cAlpha(item.$4[1], 0.35)]),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: cAlpha(Colors.white, 0.14)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text(item.$3, style: TextStyle(fontSize: 11, color: cAlpha(Colors.white, 0.72))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (ctrl.playlists.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text('Общие плейлисты', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ctrl.playlists.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final pl = ctrl.playlists[i];
                            final cnt = (ctrl.playlistMap[pl.id] ?? []).length;
                            return InkWell(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaylistDetailScreen(ctrl: ctrl, playlistId: pl.id, title: pl.name))),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 156,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: kCardGlass, borderRadius: BorderRadius.circular(18), border: Border.all(color: kCardBorder)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(pl.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                                    Text('$cnt треков', style: TextStyle(fontSize: 11, color: cAlpha(Colors.white, 0.55))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text('Все треки · ${ctrl.tracks.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          if (ctrl.isLoading && ctrl.tracks.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.white54)))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
              sliver: SliverList.separated(
                itemCount: ctrl.tracks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final t = ctrl.tracks[i];
                  return TrackRowTile(
                    track: t,
                    activeUser: user,
                    isPlaying: ctrl.currentTrack?.id == t.id,
                    accentColor: pal.c2,
                    onTap: () => ctrl.playTrack(t, customQueue: ctrl.tracks, contextLabel: 'Вся коллекция'),
                    onLike: () => ctrl.toggleLike(t),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchTab(ElysionAppController ctrl) {
    final user = ctrl.activeUser ?? 'he';
    final pal = ctrl.palette;
    final q = _searchQuery.trim().toLowerCase();
    final artists = ctrl.getArtistsSummary();
    final matchedTracks = q.isEmpty ? <Track>[] : ctrl.tracks.where((t) => ('${t.title} ${t.artist}').toLowerCase().contains(q)).toList();
    final matchedArtists = q.isEmpty ? <ArtistSummary>[] : artists.where((a) => a.name.toLowerCase().contains(q)).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Поиск', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  onSubmitted: (v) => ctrl.addRecentSearch(v),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Треки, исполнители...',
                    hintStyle: TextStyle(color: cAlpha(Colors.white, 0.42)),
                    prefixIcon: Icon(Icons.search_rounded, color: cAlpha(Colors.white, 0.5)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                          )
                        : null,
                    filled: true,
                    fillColor: kCardGlass,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide(color: kCardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide(color: kCardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide(color: pal.c2)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: q.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 160),
                    children: [
                      Text('ИСПОЛНИТЕЛИ В КОЛЛЕКЦИИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: cAlpha(Colors.white, 0.5))),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 112,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: artists.take(14).length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (_, i) {
                            final a = artists[i];
                            return GestureDetector(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArtistScreen(ctrl: ctrl, artistName: a.name))),
                              child: SizedBox(
                                width: 76,
                                child: Column(
                                  children: [
                                    TrackCover(url: a.coverUrl, size: 70, radius: 999),
                                    const SizedBox(height: 6),
                                    Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                    Text('${a.trackCount} тр.', style: TextStyle(fontSize: 10, color: cAlpha(Colors.white, 0.45))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('НЕДАВНИЕ ЗАПРОСЫ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: cAlpha(Colors.white, 0.5))),
                          if (ctrl.recentSearches.isNotEmpty)
                            TextButton(onPressed: ctrl.clearRecentSearches, child: Text('Очистить', style: TextStyle(fontSize: 11, color: cAlpha(Colors.white, 0.5)))),
                        ],
                      ),
                      if (ctrl.recentSearches.isEmpty)
                        Padding(padding: const EdgeInsets.only(top: 8), child: Text('Здесь появятся твои недавние поисковые запросы', style: TextStyle(fontSize: 12, color: cAlpha(Colors.white, 0.4))))
                      else
                        for (final term in ctrl.recentSearches)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.history_rounded, color: cAlpha(Colors.white, 0.45), size: 18),
                            title: Text(term, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            onTap: () {
                              _searchCtrl.text = term;
                              setState(() => _searchQuery = term);
                            },
                          ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 160),
                    children: [
                      if (matchedArtists.isNotEmpty) ...[
                        Text('ИСПОЛНИТЕЛИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: cAlpha(Colors.white, 0.5))),
                        const SizedBox(height: 8),
                        for (final a in matchedArtists.take(4))
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            tileColor: const Color(0x0DFFFFFF),
                            leading: TrackCover(url: a.coverUrl, size: 44, radius: 999),
                            title: Text(a.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                            subtitle: Text('${a.trackCount} треков', style: TextStyle(color: cAlpha(Colors.white, 0.5), fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                            onTap: () {
                              ctrl.addRecentSearch(_searchQuery);
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArtistScreen(ctrl: ctrl, artistName: a.name)));
                            },
                          ),
                        const SizedBox(height: 16),
                      ],
                      if (matchedTracks.isNotEmpty) ...[
                        Text('ТРЕКИ (${matchedTracks.length})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: cAlpha(Colors.white, 0.5))),
                        const SizedBox(height: 8),
                        for (final t in matchedTracks.take(40)) ...[
                          TrackRowTile(
                            track: t,
                            activeUser: user,
                            isPlaying: ctrl.currentTrack?.id == t.id,
                            accentColor: pal.c2,
                            onTap: () {
                              ctrl.addRecentSearch(_searchQuery);
                              ctrl.playTrack(t, customQueue: matchedTracks, contextLabel: 'Поиск');
                            },
                            onLike: () => ctrl.toggleLike(t),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ] else if (matchedArtists.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Center(child: Text('Ничего не найдено', style: TextStyle(color: cAlpha(Colors.white, 0.45)))),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(ElysionAppController ctrl) {
    final u = ctrl.activeUser ?? 'he';
    final p = ctrl.profiles[u];
    final partner = ctrl.profiles[ctrl.partnerId];
    final pal = ctrl.palette;
    final myLikes = ctrl.getSmartPlaylist('my-likes');
    final matches = ctrl.getSmartPlaylist('matches');
    final pinned = p?.pinnedTrackId != null ? ctrl.tracks.where((t) => t.id == p!.pinnedTrackId).firstOrNull : null;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 270,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if ((p?.bannerUrl ?? '').isNotEmpty)
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0.0, 0.56, 1.0],
                    ).createShader(r),
                    blendMode: BlendMode.dstIn,
                    child: CachedNetworkImage(imageUrl: p!.bannerUrl!, fit: BoxFit.cover),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(ctrl: ctrl))),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(color: cAlpha(Colors.black, 0.42), shape: BoxShape.circle, border: Border.all(color: cAlpha(Colors.white, 0.16))),
                                child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [pal.c1, pal.c2])),
                              child: TrackCover(url: p?.avatarUrl ?? '', size: 72, radius: 999),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p?.name ?? (u == 'she' ? 'Маша' : 'Рома'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                                  if ((p?.statusText ?? '').isNotEmpty)
                                    Text(p!.statusText, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: cAlpha(Colors.white, 0.72))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 160),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaylistDetailScreen(ctrl: ctrl, playlistId: 'my-likes', title: 'Мне нравится'))),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        height: 136,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [pal.c1, pal.c2]),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Мне нравится', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                Text('${myLikes.length} треков', style: TextStyle(fontSize: 12, color: cAlpha(Colors.white, 0.85))),
                              ],
                            ),
                            const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaylistDetailScreen(ctrl: ctrl, playlistId: 'matches', title: 'Наши совпадения'))),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        height: 136,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: kCardGlass, borderRadius: BorderRadius.circular(24), border: Border.all(color: kCardBorder)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TrackCover(url: partner?.avatarUrl ?? '', size: 42, radius: 999),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(partner?.name ?? (ctrl.partnerId == 'she' ? 'Маша' : 'Рома'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                                Text('${matches.length} совпадений', style: TextStyle(fontSize: 11, color: cAlpha(Colors.white, 0.58))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (pinned != null) ...[
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => ctrl.playTrack(pinned, contextLabel: 'Закреплённый трек'),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kCardGlass, borderRadius: BorderRadius.circular(24), border: Border.all(color: kCardBorder)),
                    child: Row(
                      children: [
                        TrackCover(url: pinned.coverUrl, size: 54, radius: 14),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ЗАКРЕПЛЁННЫЙ ТРЕК', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: pal.c2)),
                              const SizedBox(height: 3),
                              Text(pinned.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                              Text(pinned.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: cAlpha(Colors.white, 0.58))),
                            ],
                          ),
                        ),
                        const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 38),
                      ],
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}
