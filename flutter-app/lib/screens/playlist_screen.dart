import 'package:flutter/material.dart';
import '../services/audio_controller.dart';
import '../theme/elysion_theme.dart';
import '../widgets/elysion_brand.dart';
import 'player_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final ElysionAppController ctrl;
  final String playlistId;
  final String title;
  const PlaylistDetailScreen({super.key, required this.ctrl, required this.playlistId, required this.title});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final tracks = ctrl.getSmartPlaylist(playlistId);
        final user = ctrl.activeUser ?? 'he';
        final pal = ctrl.palette;
        return Scaffold(
          backgroundColor: kBgDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            actions: [
              if (tracks.isNotEmpty)
                IconButton(
                  onPressed: () {
                    ctrl.playTrack(tracks.first, customQueue: tracks, contextLabel: title);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullPlayerSheet(ctrl: ctrl)));
                  },
                  icon: Icon(Icons.play_circle_fill_rounded, color: pal.c2, size: 30),
                ),
            ],
          ),
          body: tracks.isEmpty
              ? Center(child: Text('В этом плейлисте пока пусто', style: TextStyle(color: cAlpha(Colors.white, 0.5))))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: tracks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final t = tracks[i];
                    return TrackRowTile(
                      track: t,
                      activeUser: user,
                      isPlaying: ctrl.currentTrack?.id == t.id,
                      accentColor: pal.c2,
                      onTap: () => ctrl.playTrack(t, customQueue: tracks, contextLabel: title),
                      onLike: () => ctrl.toggleLike(t),
                    );
                  },
                ),
        );
      },
    );
  }
}
