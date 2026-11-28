import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/audio_controller.dart';
import '../theme/elysion_theme.dart';
import '../widgets/elysion_brand.dart';
import 'player_screen.dart';

class ArtistScreen extends StatelessWidget {
  final ElysionAppController ctrl;
  final String artistName;
  const ArtistScreen({super.key, required this.ctrl, required this.artistName});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final user = ctrl.activeUser ?? 'he';
        final pal = ctrl.palette;
        final tracks = ctrl.getArtistTracks(artistName);
        final matches = tracks.where((t) => t.isMatch).length;
        final heroImg = tracks.isNotEmpty ? tracks.first.coverUrl : '';

        final topRanked = List<Track>.from(tracks)
          ..sort((a, b) {
            final sa = (ctrl.localTrackPlays[a.id] ?? 0) + (a.isMatch ? 3 : (a.isLikedBy(user) ? 1 : 0));
            final sb = (ctrl.localTrackPlays[b.id] ?? 0) + (b.isMatch ? 3 : (b.isLikedBy(user) ? 1 : 0));
            return sb.compareTo(sa);
          });
        final top5 = topRanked.take(5).toList();

        return Scaffold(
          backgroundColor: kBgDark,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 310,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (heroImg.isNotEmpty)
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.white, Colors.transparent],
                            stops: [0.0, 0.55, 1.0],
                          ).createShader(rect),
                          blendMode: BlendMode.dstIn,
                          child: CachedNetworkImage(imageUrl: heroImg, fit: BoxFit.cover),
                        ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(color: cAlpha(Colors.black, 0.45), shape: BoxShape.circle, border: Border.all(color: cAlpha(Colors.white, 0.16))),
                                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ИСПОЛНИТЕЛЬ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.2, color: cAlpha(Colors.white, 0.72))),
                                  const SizedBox(height: 4),
                                  Text(artistName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      _statPill('${tracks.length} треков', Colors.white),
                                      if (matches > 0) _statPill('$matches совп.', pal.c2),
                                    ],
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: kBgDark,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: tracks.isEmpty
                                ? null
                                : () {
                                    ctrl.playTrack(tracks.first, customQueue: tracks, contextLabel: artistName);
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullPlayerSheet(ctrl: ctrl)));
                                  },
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            label: const Text('Слушать', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: cAlpha(Colors.white, 0.18)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: tracks.isEmpty
                                ? null
                                : () {
                                    final shuffled = List<Track>.from(tracks)..shuffle();
                                    ctrl.playTrack(shuffled.first, customQueue: shuffled, contextLabel: 'Микс · $artistName');
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullPlayerSheet(ctrl: ctrl)));
                                  },
                            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                            label: const Text('Микс', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                    if (top5.length >= 2) ...[
                      const SizedBox(height: 24),
                      const Text('Топ треков', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 10),
                      for (int i = 0; i < top5.length; i++) ...[
                        TrackRowTile(
                          track: top5[i],
                          activeUser: user,
                          isPlaying: ctrl.currentTrack?.id == top5[i].id,
                          accentColor: pal.c2,
                          rankNumber: i + 1,
                          onTap: () => ctrl.playTrack(top5[i], customQueue: top5, contextLabel: 'Топ · $artistName'),
                          onLike: () => ctrl.toggleLike(top5[i]),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                    const SizedBox(height: 18),
                    const Text('Все треки', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 10),
                    for (final t in tracks) ...[
                      TrackRowTile(
                        track: t,
                        activeUser: user,
                        isPlaying: ctrl.currentTrack?.id == t.id,
                        accentColor: pal.c2,
                        onTap: () => ctrl.playTrack(t, customQueue: tracks, contextLabel: artistName),
                        onLike: () => ctrl.toggleLike(t),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statPill(String text, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: cAlpha(Colors.black, 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cAlpha(Colors.white, 0.16)),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
      );
}
