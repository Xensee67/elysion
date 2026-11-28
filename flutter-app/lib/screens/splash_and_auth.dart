import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_controller.dart';
import '../theme/elysion_theme.dart';
import '../widgets/elysion_brand.dart';

class ElysionSplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ElysionSplashScreen({super.key, required this.onDone});

  @override
  State<ElysionSplashScreen> createState() => _ElysionSplashScreenState();
}

class _ElysionSplashScreenState extends State<ElysionSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
    Future.delayed(const Duration(milliseconds: 1450), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ElysionTwinStars(size: 112),
                const SizedBox(height: 18),
                Text(
                  'ELYSION',
                  style: GoogleFonts.cinzel(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 7,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatelessWidget {
  final ElysionAppController ctrl;
  const AuthScreen({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ElysionTwinStars(size: 72),
              const SizedBox(height: 14),
              Text(
                'ELYSION',
                style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 6, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text('Выбери свой профиль', style: TextStyle(fontSize: 13, color: cAlpha(Colors.white, 0.55))),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(child: _profileCard('Рома', 'Р', const [Color(0xFF9333EA), Color(0xFF4F46E5)], () => ctrl.selectUser('he'))),
                  const SizedBox(width: 14),
                  Expanded(child: _profileCard('Маша', 'М', const [Color(0xFFEC4899), Color(0xFFD946EF)], () => ctrl.selectUser('she'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard(String name, String letter, List<Color> grad, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        decoration: BoxDecoration(
          color: kCardGlass,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: kCardBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: grad),
                border: Border.all(color: cAlpha(Colors.white, 0.25), width: 2),
              ),
              alignment: Alignment.center,
              child: Text(letter, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(height: 14),
            Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
