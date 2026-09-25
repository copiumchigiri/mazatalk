import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum SpeechAttemptResult {
  /// Recognized words contained the target word.
  matched,

  /// Something was heard (speech detected, or a transcription came back)
  /// but it didn't match the target word.
  vocalized,

  /// Listened for the full window and heard nothing.
  silent,

  /// No recognizer available (missing plugin, denied permission, no
  /// speech service on the device, or any other failure). Never thrown —
  /// callers must treat this the same as [silent], never as an error.
  unavailable,
}

class SpeechAttempt {
  final SpeechAttemptResult result;
  final String recognizedWords;
  const SpeechAttempt(this.result, {this.recognizedWords = ''});
}

/// Best-effort speech capture for the placement playground's "Repeat After
/// Me" level (PROJECT_V4.md §6 Level 2). This is diagnostic only — never
/// pronunciation grading, never blocking (§9): every failure mode (no
/// plugin, denied mic permission, no recognizer on the device) degrades to
/// [SpeechAttemptResult.unavailable] instead of throwing, so a level that
/// depends on this service can always complete.
class SpeechInputService {
  final stt.SpeechToText _speech;
  bool? _available;

  SpeechInputService({stt.SpeechToText? speech})
    : _speech = speech ?? stt.SpeechToText();

  Future<bool> _ensureAvailable() async {
    if (_available != null) return _available!;
    try {
      _available = await _speech.initialize(onError: (_) {}, onStatus: (_) {});
    } catch (_) {
      _available = false;
    }
    return _available!;
  }

  /// Listens for up to [timeout], comparing the best transcription against
  /// [targetWord] (case-insensitive, punctuation-stripped substring match —
  /// lenient on purpose, this is a comfort probe, not a grader). Always
  /// resolves within roughly [timeout]; never throws.
  Future<SpeechAttempt> listenFor(
    String targetWord, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final available = await _ensureAvailable();
      if (!available) {
        return const SpeechAttempt(SpeechAttemptResult.unavailable);
      }

      var heard = '';
      var heardAnySound = false;
      final localeId = await _pickLocale();

      await _speech.listen(
        onResult: (result) => heard = result.recognizedWords,
        onSoundLevelChange: (level) {
          if (level > _soundDetectedThreshold) heardAnySound = true;
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: timeout,
          pauseFor: timeout,
          partialResults: true,
          localeId: localeId,
        ),
      );

      await Future.delayed(timeout);
      await _speech.stop();

      if (heard.isNotEmpty && _looksLikeMatch(heard, targetWord)) {
        return SpeechAttempt(
          SpeechAttemptResult.matched,
          recognizedWords: heard,
        );
      }
      if (heard.isNotEmpty || heardAnySound) {
        return SpeechAttempt(
          SpeechAttemptResult.vocalized,
          recognizedWords: heard,
        );
      }
      return const SpeechAttempt(SpeechAttemptResult.silent);
    } catch (_) {
      return const SpeechAttempt(SpeechAttemptResult.unavailable);
    }
  }

  /// Prefers a Mongolian recognizer; null lets the platform use its default
  /// (many devices ship none, in which case results just stay empty and the
  /// level scores the attempt as vocalized/silent — never as an error).
  Future<String?> _pickLocale() async {
    try {
      final locales = await _speech.locales();
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith('mn')) return l.localeId;
      }
    } catch (_) {}
    return null;
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  // The sound-level scale differs by platform and isn't documented for
  // Android; this threshold is a rough "louder than ambient" heuristic used
  // only as a fallback when transcription comes back empty.
  static const _soundDetectedThreshold = -25.0;

  static bool _looksLikeMatch(String heard, String target) {
    String normalize(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-zа-яёөү]'), '');
    final normalizedTarget = normalize(target);
    return normalizedTarget.isNotEmpty &&
        normalize(heard).contains(normalizedTarget);
  }
}

final speechInputServiceProvider = Provider<SpeechInputService>((ref) {
  final service = SpeechInputService();
  ref.onDispose(service.stop);
  return service;
});
