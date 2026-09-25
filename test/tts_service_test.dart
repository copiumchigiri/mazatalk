import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazatalk/core/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clipKey matches the file names tools/generate_tts.py writes', () {
    // Names taken from the generator's output for these exact phrases.
    expect(TtsService.clipKey('Хэдэн хонь байна вэ?'), 'b8aa0220a8eb');
    expect(TtsService.clipKey('Улаан өнгийг дар!'), 'df56dd36092c');
  });

  test('every playground prompt has a bundled clip', () async {
    for (final phrase in [
      'Бөмбөг бутанд нуугдсан байна. Ол!',
      "'бөмбөг' гэж хэлээрэй!",
      'Дугуйг зөв нүхэнд нь хий!',
      'Мазагийн үүргэвчинд дуртай 3 зүйлээ хий!',
      'Маза бөмбөгөө алджээ. Тусалцгаая!',
    ]) {
      final data = await rootBundle.load(
        'assets/audio/tts/${TtsService.clipKey(phrase)}.mp3',
      );
      expect(data.lengthInBytes, greaterThan(1000), reason: phrase);
    }
  });
}
