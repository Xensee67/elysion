import 'package:flutter/material.dart';
import '../services/audio_controller.dart';
import '../theme/elysion_theme.dart';

class SettingsScreen extends StatelessWidget {
  final ElysionAppController ctrl;
  const SettingsScreen({super.key, required this.ctrl});

  static const _bgModes = [
    ('mesh', 'Облачный Mesh', '4 цвета обложки (120 FPS)'),
    ('silk', 'Шёлковый Mesh', 'Глубокий жидкий шёлк'),
    ('bloom', 'OLED-гало', 'Свечение вокруг обложки'),
    ('static', 'Статичный', 'Экономия заряда'),
  ];

  void _openChangelog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF120B24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cAlpha(Colors.white, 0.2), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            const Text('История обновлений', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 14),
            for (final item in elysionNativeChangelog)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: cAlpha(Colors.white, 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cAlpha(ctrl.palette.c2, 0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [ctrl.palette.c1, ctrl.palette.c2]),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(item.version, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        Text('«${item.name}»', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.description, style: TextStyle(fontSize: 12, height: 1.45, color: cAlpha(Colors.white, 0.72))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final pal = ctrl.palette;
        return Scaffold(
          backgroundColor: kBgDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              // 8 Accent Palettes
              _sectionCard(
                title: 'Акцентная палитра',
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.5),
                  itemCount: elysionPalettes.length,
                  itemBuilder: (_, i) {
                    final p = elysionPalettes[i];
                    final on = p.id == ctrl.paletteId;
                    return InkWell(
                      onTap: () => ctrl.setPalette(p.id),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: on ? cAlpha(Colors.white, 0.14) : cAlpha(Colors.white, 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: on ? p.c2 : cAlpha(Colors.white, 0.10)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [p.c1, p.c2]))),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // 4 Live Player Mesh Modes
              _sectionCard(
                title: 'Живой фон плеера (120 FPS)',
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.1),
                  itemCount: _bgModes.length,
                  itemBuilder: (_, i) {
                    final m = _bgModes[i];
                    final on = m.$1 == ctrl.playerBgStyle;
                    return InkWell(
                      onTap: () => ctrl.setPlayerBgStyle(m.$1),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: on ? cAlpha(Colors.white, 0.14) : cAlpha(Colors.white, 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: on ? pal.c2 : cAlpha(Colors.white, 0.10)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(m.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(m.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: cAlpha(Colors.white, 0.55))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Changelog button
              InkWell(
                onTap: () => _openChangelog(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kCardGlass, borderRadius: BorderRadius.circular(24), border: Border.all(color: kCardBorder)),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, color: Colors.white70),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('История обновлений', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text('Elysion Native $elysionNativeVersion · «$elysionNativeVersionName»', style: TextStyle(fontSize: 11, color: cAlpha(Colors.white, 0.55))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: cAlpha(Colors.white, 0.10), borderRadius: BorderRadius.circular(999)),
                        child: Text(elysionNativeVersion, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: pal.c2)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Switch Profile
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFDA4AF),
                  side: BorderSide(color: cAlpha(const Color(0xFFF43F5E), 0.35)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  ctrl.logoutUser();
                  Navigator.of(context).pop();
                },
                child: const Text('Сменить профиль', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),

              // Dynamic Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Elysion Native $elysionNativeVersion', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cAlpha(Colors.white, 0.40))),
                    Text('Разработано : Xensee Studio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cAlpha(Colors.white, 0.40))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionCard({required String title, required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kCardGlass, borderRadius: BorderRadius.circular(24), border: Border.all(color: kCardBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}
