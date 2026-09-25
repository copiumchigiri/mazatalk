import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../features/settings/application/settings_controller.dart';

/// Child-friendly Mongolian speech. Phone TTS engines rarely ship a
/// Mongolian voice, so every fixed phrase is pre-generated as an mp3
/// (`tools/generate_tts.py`, phrases in `tools/tts_phrases.txt`) and played
/// from assets. Text without a clip falls back to the device voice set to
/// `mn-MN`. Every failure is swallowed — a missing engine or clip must never
/// crash a lesson.
class TtsService {
  static const _clipDir = 'assets/audio/tts';

  final FlutterTts _tts = FlutterTts();
  AudioPlayer? _player;
  bool enabled;
  bool _initialized = false;

  TtsService({this.enabled = true});

  /// Clip file key for [text]: first 12 hex chars of sha1 — must match
  /// `key()` in `tools/generate_tts.py`.
  @visibleForTesting
  static String clipKey(String text) =>
      sha1.convert(utf8.encode(text)).toString().substring(0, 12);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _tts.setLanguage('mn-MN');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.1);
    } catch (_) {
      // No TTS engine (tests, stripped emulators): stay silent.
    }
  }

  Future<void> speak(String text) async {
    if (!enabled || text.isEmpty) return;
    await stop();
    final clipPath = '$_clipDir/${clipKey(text)}.mp3';
    try {
      await rootBundle.load(clipPath); // throws when no clip exists
      _player ??= AudioPlayer();
      // AssetSource prepends "assets/" itself.
      await _player!.play(AssetSource(clipPath.substring('assets/'.length)));
      return;
    } catch (_) {
      if (kDebugMode) debugPrint('TtsService: no clip for "$text"');
    }
    await _ensureInitialized();
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _player?.dispose();
    } catch (_) {}
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService(
    enabled: ref.watch(settingsControllerProvider.select((s) => s.soundOn)),
  );
  ref.onDispose(service.dispose);
  return service;
});
