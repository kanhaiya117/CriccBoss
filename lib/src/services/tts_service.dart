import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService();

  final _tts = FlutterTts();

  Future<void> configure(CommentaryLanguage language) async {
    await _tts.setLanguage(
      language == CommentaryLanguage.hindi ? 'hi-IN' : 'en-IN',
    );
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1);
  }

  Future<void> speak(
    CommentaryEvent event,
    VoiceMode mode,
    CommentaryLanguage language,
  ) async {
    if (mode == VoiceMode.off) return;
    if (mode == VoiceMode.importantOnly && !event.isImportant) return;
    await configure(language);
    await _tts.speak(
      language == CommentaryLanguage.hindi
          ? event.hindiText ?? event.text
          : event.text,
    );
  }

  Future<void> stop() => _tts.stop();
}
