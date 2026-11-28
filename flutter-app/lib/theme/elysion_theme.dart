import 'package:flutter/material.dart';

const String elysionNativeVersion = 'v1.0';
const String elysionNativeVersionName = 'Нативный рассвет';

class NativeChangelogItem {
  final String version;
  final String name;
  final String description;
  const NativeChangelogItem(this.version, this.name, this.description);
}

const List<NativeChangelogItem> elysionNativeChangelog = [
  NativeChangelogItem(
    'v1.0',
    'Нативный рассвет',
    'Первый нативный релиз Elysion на Flutter (120 FPS Impeller): аппаратный фоновый звук на ExoPlayer с Live Alerts и Bluetooth-управлением, общая облачная база с iPhone PWA, все 8 акцентных палитр, Библиотека, Поиск, Карточка артиста с Топ-5 треков, Профиль «Бенто-люкс» и полноэкранный плеер с 120 FPS Mesh-градиентом и плавным синхронизированным текстом.',
  ),
];

Color cAlpha(Color c, double a) => c.withAlpha((a.clamp(0.0, 1.0) * 255).round());

class ElysionPalette {
  final String id;
  final String name;
  final Color c1;
  final Color c2;
  final Color c3;
  const ElysionPalette(this.id, this.name, this.c1, this.c2, this.c3);
}

const List<ElysionPalette> elysionPalettes = [
  ElysionPalette('violet-rose', 'Неон × Роза', Color(0xFF9333EA), Color(0xFFEC4899), Color(0xFF6366F1)),
  ElysionPalette('violet-cyan', 'Ультра × Циан', Color(0xFF7C3AED), Color(0xFF06B6D4), Color(0xFF3B82F6)),
  ElysionPalette('violet-gold', 'Аметист × Золото', Color(0xFF8B5CF6), Color(0xFFF59E0B), Color(0xFFEC4899)),
  ElysionPalette('emerald-silver', 'Изумруд × Серебро', Color(0xFF10B981), Color(0xFF94A3B8), Color(0xFF06B6D4)),
  ElysionPalette('ruby-neon', 'Рубин × Неон', Color(0xFFE11D48), Color(0xFFF43F5E), Color(0xFFA855F7)),
  ElysionPalette('sunset-coral', 'Закат × Коралл', Color(0xFFF97316), Color(0xFFFB7185), Color(0xFFEC4899)),
  ElysionPalette('midnight-ice', 'Полночный Лёд', Color(0xFF2563EB), Color(0xFF38BDF8), Color(0xFF6366F1)),
  ElysionPalette('obsidian-silver', 'Обсидиан × Серебро', Color(0xFF475569), Color(0xFF94A3B8), Color(0xFF334155)),
];

ElysionPalette paletteById(String id) {
  return elysionPalettes.firstWhere((p) => p.id == id, orElse: () => elysionPalettes.first);
}

const Color kBgDark = Color(0xFF07040F);
const Color kCardGlass = Color(0x14FFFFFF);
const Color kCardBorder = Color(0x1EFFFFFF);
