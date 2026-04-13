import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AlarmService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static Timer? _timer;
  static Timer? _watcher;

  static List<dynamic> _events = [];
  static Function(dynamic)? _callback;

  /// 🔔 Déclencher alarme
  static Future<void> triggerAlarm() async {
    try {
      HapticFeedback.heavyImpact();

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('alarm.mp3'));

      print("INFO: Alarme déclenchée");
    } catch (e) {
      print("ERREUR Alarme: $e");
    }
  }

  /// 🛑 Stop alarme
  static Future<void> stopAlarm() async {
    await _audioPlayer.stop();
    _timer?.cancel();
  }

  /// ▶️ Lancer le watcher
  static void startWatcher(List<dynamic> events, Function(dynamic) callback) {
    _events = events;
    _callback = callback;

    _watcher?.cancel();

    _watcher = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkEvents();
    });
  }

  /// 🔄 Mise à jour des événements
  static void updateEvents(List<dynamic> events, Function(dynamic) callback) {
    _events = events;
    _callback = callback;
  }

  /// ❌ Stop watcher
  static void stopWatcher() {
    _watcher?.cancel();
  }

  /// 🔍 Vérification des événements
  static void _checkEvents() {
    final now = DateTime.now();

    for (var event in _events) {
      final eventTime = DateTime.parse(event['start_at']).toLocal();
      final diff = eventTime.difference(now).inMinutes;

      if (diff == 0) {
        triggerAlarm();
        _callback?.call({...event, 'warning': false});
      }

      if (diff == 5) {
        _callback?.call({...event, 'warning': true});
      }
    }
  }

  /// 🧹 Dispose
  static void dispose() {
    _audioPlayer.dispose();
    _timer?.cancel();
    _watcher?.cancel();
  }
}