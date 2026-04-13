// mobile/lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> init() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.90);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.setSharedInstance(true); // Important pour Android/iOS
  }

  static Future<void> speakDailyProgram(String userName, List<dynamic> events) async {
    if (events.isEmpty) {
      await _tts.speak("Bonjour $userName, vous n'avez aucun événement aujourd'hui. Bonne journée !");
      return;
    }

    String text = "Bonjour $userName, vous avez ${events.length} événement";
    if (events.length > 1) text += "s";
    text += " aujourd'hui. ";

    // Tri par heure
    events.sort((a, b) {
      return DateTime.parse(a['start_at']).compareTo(DateTime.parse(b['start_at']));
    });

    for (var event in events) {
      final dateTime = DateTime.parse(event['start_at']).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      text += "À $hour:$minute : ${event['title']}. ";

      if (event['location'] != null && event['location'].toString().isNotEmpty) {
        text += "Lieu : ${event['location']}. ";
      }
    }

    await _tts.speak(text);
    print("🗣️ TTS lancé : $text");
  }

  static Future<void> stop() async {
    await _tts.stop();
  }
}