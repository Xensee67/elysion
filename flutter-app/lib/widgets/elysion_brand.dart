import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/elysion_theme.dart';

class ElysionTwinStars extends StatelessWidget {
  final double size;
  const ElysionTwinStars({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _TwinStarsPainter());
  }
}

class _TwinStarsPainter extends CustomPainter {
  Path _fourPointStar(Offset center, double r) {
    final path = Path();
    final inner = r * 0.22;
    path.moveTo(center.dx, center.dy - r);
    path.quadraticBezierTo(center.dx + inner, center.dy - inner, center.dx + r, center.dy);
    path.quadraticBezierTo(center.dx + inner, center.dy + inner, center.dx, center.dy + r);
    path.quadraticBezierTo(center.dx - inner, center.dy + inner, center.dx - r, center.dy);
    path.quadraticBezierTo(center.dx - inner, center.dy - inner, center.dx, center.dy - r);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120.0;
    final p1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0), Color(0xFFC084FC)],
      ).createShader(Offset.zero & size);
    final p2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF472B6), Color(0xFF9333EA)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(_fourPointStar(Offset(52 * s, 48 * s), 34 * s), p1);
    canvas.drawPath(_fourPointStar(Offset(88 * s, 72 * s), 18 * s), p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrackCover extends StatelessWidget {
  final String url;
  final double size;
  final double radius;
  const TrackCover({super.key, required this.url, this.size = 48, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: const Color(0x18FFFFFF)),
                errorWidget: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF3B1D60), Color(0xFF1A1033)]),
        ),
        child: Icon(Icons.music_note_rounded, color: cAlpha(Colors.white, 0.4), size: size * 0.45),
      );
}

class TrackRowTile extends StatelessWidget {
  final Track track;
  final String activeUser;
  final bool isPlaying;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final int? rankNumber;

  const TrackRowTile({
    super.key,
    required this.track,
    required this.activeUser,
    required this.isPlaying,
    required this.accentColor,
    required this.onTap,
    required this.onLike,
    this.rankNumber,
  });

  @override
  Widget build(BuildContext context) {
    final liked = track.isLikedBy(activeUser);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isPlaying ? cAlpha(accentColor, 0.16) : const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isPlaying ? cAlpha(accentColor, 0.45) : const Color(0x12FFFFFF)),
        ),
        child: Row(
          children: [
            if (rankNumber != null)
              SizedBox(
                width: 24,
                child: Text(
                  '$rankNumber',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: rankNumber == 1 ? accentColor : cAlpha(Colors.white, 0.45),
                  ),
                ),
              ),
            TrackCover(url: track.coverUrl, size: 46, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isPlaying ? accentColor : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: cAlpha(Colors.white, 0.55)),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onLike,
              icon: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20,
                color: liked ? accentColor : cAlpha(Colors.white, 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
