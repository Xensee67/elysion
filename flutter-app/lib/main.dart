import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_shell.dart';
import 'screens/splash_and_auth.dart';
import 'services/audio_controller.dart';
import 'theme/elysion_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final audioHandler = await AudioService.init(
    builder: () => ElysionAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.elysion.native.playback',
      androidNotificationChannelName: 'Elysion Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  final ctrl = ElysionAppController(audioHandler);
  await ctrl.init();
  runApp(ElysionNativeApp(ctrl: ctrl));
}

class ElysionNativeApp extends StatefulWidget {
  final ElysionAppController ctrl;
  const ElysionNativeApp({super.key, required this.ctrl});

  @override
  State<ElysionNativeApp> createState() => _ElysionNativeAppState();
}

class _ElysionNativeAppState extends State<ElysionNativeApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.ctrl,
      builder: (_, __) {
        final pal = widget.ctrl.palette;
        return MaterialApp(
          title: 'Elysion',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: kBgDark,
            colorScheme: ColorScheme.dark(primary: pal.c1, secondary: pal.c2, surface: kBgDark),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
            useMaterial3: true,
          ),
          home: !_splashDone
              ? ElysionSplashScreen(onDone: () => setState(() => _splashDone = true))
              : widget.ctrl.activeUser == null
                  ? AuthScreen(ctrl: widget.ctrl)
                  : HomeShell(ctrl: widget.ctrl),
        );
      },
    );
  }
}
