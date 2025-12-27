import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Сервис голосовой озвучки через Google TTS
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isEnabled = true;
  String? _currentLanguage; // e.g. 'ru-RU', 'uz-UZ'

  /// Инициализация TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _flutterTts = FlutterTts();

      // Настройки для Android
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _flutterTts?.setEngine('com.google.android.tts');
      }

      // Базовые настройки (язык синхронизируем отдельно)
      await _flutterTts?.setLanguage('ru-RU'); // дефолт
      await _flutterTts?.setSpeechRate(0.45); // Скорость речи (0.1 - 2.0) - замедлена для лучшего восприятия
      await _flutterTts?.setVolume(1.0); // Громкость (0.0 - 1.0)
      await _flutterTts?.setPitch(1.0); // Высота голоса (0.5 - 2.0)

      // Обработчики событий
      _flutterTts?.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('🔊 TTS: Начало озвучки');
      });

      _flutterTts?.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('🔊 TTS: Озвучка завершена');
      });

      _flutterTts?.setErrorHandler((message) {
        _isSpeaking = false;
        debugPrint('❌ TTS Error: $message');
      });

      _isInitialized = true;
      debugPrint('✅ VoiceService инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации VoiceService: $e');
    }
  }

  /// Озвучить текст
  Future<void> speak(String text) async {
    if (!_isEnabled || !_isInitialized || text.isEmpty) return;

    try {
      // Останавливаем предыдущую озвучку
      if (_isSpeaking) {
        await stop();
      }

      debugPrint('🔊 Озвучиваем: "$text"');
      await _flutterTts?.speak(text);
    } catch (e) {
      debugPrint('❌ Ошибка озвучки: $e');
    }
  }

  /// Остановить озвучку
  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts?.stop();
      _isSpeaking = false;
      debugPrint('🔇 Озвучка остановлена');
    } catch (e) {
      debugPrint('❌ Ошибка остановки озвучки: $e');
    }
  }

  /// Пауза озвучки
  Future<void> pause() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts?.pause();
      debugPrint('⏸️ Озвучка на паузе');
    } catch (e) {
      debugPrint('❌ Ошибка паузы озвучки: $e');
    }
  }

  /// Включить/выключить озвучку
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    debugPrint('🔊 Озвучка ${enabled ? 'включена' : 'выключена'}');
    
    if (!enabled && _isSpeaking) {
      stop();
    }
  }

  /// Проверить включена ли озвучка
  bool get isEnabled => _isEnabled;

  /// Проверить говорит ли сейчас
  bool get isSpeaking => _isSpeaking;

  /// Установить скорость речи
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) return;
    
    try {
      await _flutterTts?.setSpeechRate(rate.clamp(0.1, 2.0));
      debugPrint('🔊 Скорость речи установлена: $rate');
    } catch (e) {
      debugPrint('❌ Ошибка установки скорости речи: $e');
    }
  }

  /// Установить громкость
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;
    
    try {
      await _flutterTts?.setVolume(volume.clamp(0.0, 1.0));
      debugPrint('🔊 Громкость установлена: $volume');
    } catch (e) {
      debugPrint('❌ Ошибка установки громкости: $e');
    }
  }

  /// Получить доступные языки
  Future<List<String>> getLanguages() async {
    if (!_isInitialized) return [];
    
    try {
      final languages = await _flutterTts?.getLanguages;
      return List<String>.from(languages ?? []);
    } catch (e) {
      debugPrint('❌ Ошибка получения языков: $e');
      return [];
    }
  }

  /// Установить язык
  Future<void> setLanguage(String language) async {
    if (!_isInitialized) return;
    
    try {
      await _flutterTts?.setLanguage(language);
      debugPrint('🔊 Язык установлен: $language');
      _currentLanguage = language;
    } catch (e) {
      debugPrint('❌ Ошибка установки языка: $e');
    }
  }

  /// Синхронизация языка TTS по языку приложения (например, 'ru', 'uz', 'ru-RU')
  /// Возвращает фактически установленный язык
  Future<String?> syncLanguageByLocale(String appLocale) async {
    if (!_isInitialized) return null;

    try {
      final desired = _mapAppLocaleToTts(appLocale);
      // Если уже установлен тот же — ничего не делаем
      if (_currentLanguage == desired) return _currentLanguage;

      final supported = await getLanguages();
      // Порядок предпочтений: desired, ru-RU, uz-UZ, en-US
      final candidates = <String>[
        desired,
        // для узбекского fallback часто на русский в наших краях
        'ru-RU',
        'uz-UZ',
        'en-US',
      ];

      for (final c in candidates) {
        if (supported.contains(c)) {
          await setLanguage(c);
          return c;
        }
      }

      // Если ничего не подошло — пробуем установить desired вслепую
      await setLanguage(desired);
      return desired;
    } catch (e) {
      debugPrint('❌ Ошибка синхронизации языка TTS: $e');
      return _currentLanguage;
    }
  }

  /// Текущее установленное значение языка TTS
  String? get currentLanguage => _currentLanguage;

  String _mapAppLocaleToTts(String appLocale) {
    final l = appLocale.toLowerCase();
    if (l.startsWith('ru')) return 'ru-RU';
    if (l.startsWith('uz')) return 'uz-UZ';
    return 'ru-RU';
  }

  /// Освободить ресурсы
  void dispose() {
    _flutterTts?.stop();
    _flutterTts = null;
    _isInitialized = false;
    _isSpeaking = false;
    debugPrint('🔊 VoiceService освобожден');
  }
}

/// Готовые фразы для навигации
class NavigationPhrases {
  static const String routeCalculated = 'Маршрут построен';
  static const String navigationStarted = 'Навигация началась';
  static const String navigationStopped = 'Навигация завершена';
  static const String destinationReached = 'Вы прибыли к месту назначения';
  static const String recalculating = 'Пересчитываю маршрут';
  static const String turnLeft = 'Поверните налево';
  static const String turnRight = 'Поверните направо';
  static const String goStraight = 'Продолжайте прямо';
  static const String uturn = 'Разворот';
  static const String roundabout = 'Въезд на кольцо';
  static const String exitRoundabout = 'Съезд с кольца';
  static const String overspeed = 'Вы превышаете разрешенную скорость';
  
  /// Получить фразу для маневра
  static String getManeuverPhrase(String type, String? modifier) {
    switch (type) {
      case 'turn':
        switch (modifier) {
          case 'left':
          case 'slight left':
          case 'sharp left':
            return turnLeft;
          case 'right':
          case 'slight right':
          case 'sharp right':
            return turnRight;
          default:
            return goStraight;
        }
      case 'continue':
      case 'straight':
        return goStraight;
      case 'uturn':
        return uturn;
      case 'roundabout':
        return roundabout;
      case 'exit roundabout':
        return exitRoundabout;
      case 'arrive':
        return destinationReached;
      default:
        return 'Следуйте по маршруту';
    }
  }

  /// Получить фразу с расстоянием
  static String getDistancePhrase(double distanceMeters) {
    if (distanceMeters < 50) {
      return 'через ${distanceMeters.round()} метров';
    } else if (distanceMeters < 1000) {
      final meters = (distanceMeters / 50).round() * 50;
      return 'через $meters метров';
    } else {
      final km = (distanceMeters / 1000).toStringAsFixed(1);
      return 'через $km километров';
    }
  }

  /// Фраза о превышении скорости с указанием лимита
  static String getOverspeedPhrase(int limitKmh) {
    return '$overspeed $limitKmh километров в час';
  }
}
