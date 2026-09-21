import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../features/settings/application/settings_controller.dart';

/// Child-friendly text-to-speech: slow rate, every failure swallowed (a
/// missing TTS engine must never crash a lesson — the tile highlights still
/// carry the feedback). Pre-readers rely on this voice for prompts.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool enabled;
  bool _initialized = false;

  TtsService({this.enabled = true});

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.1);
    } catch (_) {
      // No TTS engine (tests, stripped emulators): stay silent.
    }
  }

  Future<void> speak(String text) async {
    if (!enabled || text.isEmpty) return;
    await _ensureInitialized();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService(
    enabled: ref.watch(settingsControllerProvider.select((s) => s.soundOn)),
  );
  ref.onDispose(service.stop);
  return service;
});
