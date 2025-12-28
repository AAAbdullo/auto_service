import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Сервис для голосовых подсказок TTS (Text-to-Speech)
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Инициализация TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Настройка языка
      await _flutterTts.setLanguage('ru-RU');

      // Настройка скорости речи (0.5 - медленно, 1.0 - нормально, 1.5 - быстро)
      await _flutterTts.setSpeechRate(0.5);

      // Настройка громкости (0.0 - 1.0)
      await _flutterTts.setVolume(1.0);

      // Настройка тона (0.5 - низкий, 1.0 - нормальный, 2.0 - высокий)
      await _flutterTts.setPitch(1.0);

      // Обработчики событий
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('🔊 TTS: Начало озвучивания');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('✅ TTS: Озвучивание завершено');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('❌ TTS Error: $msg');
      });

      _isInitialized = true;
      debugPrint('✅ TTS Service инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации TTS: $e');
    }
  }

  /// Озвучить текст
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Если уже озвучивается, останавливаем предыдущее
      if (_isSpeaking) {
        await _flutterTts.stop();
      }

      debugPrint('🔊 TTS: "$text"');
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('❌ Ошибка озвучивания: $e');
    }
  }

  /// Остановить озвучивание
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('❌ Ошибка остановки TTS: $e');
    }
  }

  /// Озвучить начало навигации
  Future<void> announceNavigationStart(
    String destination,
    double distanceKm,
    int durationMin,
  ) async {
    final text =
        'Начинаем навигацию. Расстояние до цели ${distanceKm.toStringAsFixed(1)} километров. Время в пути примерно $durationMin минут.';
    await speak(text);
  }

  /// Озвучить приближение к точке
  Future<void> announceApproaching(double distanceMeters) async {
    if (distanceMeters < 50) {
      await speak('Вы прибыли в пункт назначения');
    } else if (distanceMeters < 100) {
      await speak('Через 100 метров вы прибудете в пункт назначения');
    } else if (distanceMeters < 200) {
      await speak('Через 200 метров вы прибудете в пункт назначения');
    } else if (distanceMeters < 500) {
      await speak('Через 500 метров вы прибудете в пункт назначения');
    }
  }

  /// Озвучить завершение навигации
  Future<void> announceNavigationComplete() async {
    await speak('Вы прибыли в пункт назначения. Навигация завершена.');
  }

  /// Озвучить отмену навигации
  Future<void> announceNavigationCancelled() async {
    await speak('Навигация остановлена');
  }

  /// Проверка, озвучивается ли сейчас текст
  bool get isSpeaking => _isSpeaking;

  /// Освободить ресурсы
  Future<void> dispose() async {
    await stop();
  }
}
