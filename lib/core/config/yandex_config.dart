/// Конфигурация API ключей Яндекс сервисов
class YandexConfig {
  /// API ключ для MapKit – мобильный SDK (карты, геолокация, UI)
  /// Используется для:
  /// - Отображения карт
  /// - Встроенного индикатора пользователя
  /// - Управления камерой карты
  /// - Маркеров и объектов на карте
  static const String mapKitApiKey = '21ce4ce6-0677-46c6-9f24-d669e0d8f2ef';

  /// API ключ для Матрица Расстояний и Построение Маршрута
  /// Используется для:
  /// - Построения маршрутов через Router API
  /// - Получения детальной геометрии маршрутов
  /// - Расчета времени и расстояния
  /// - Информации о маневрах
  /// ⚠️ ВАЖНО: Нужен ОТДЕЛЬНЫЙ ключ для Router API!
  /// Получить здесь: https://developer.tech.yandex.ru/services/3
  /// Текущий ключ MapKit не работает для Router API (401 ошибка)
  static const String routingApiKey = '21ce4ce6-0677-46c6-9f24-d669e0d8f2ef';

  /// Базовый URL для Router API
  static const String routingBaseUrl =
      'https://api.routing.yandex.net/v2/route';

  /// Проверка валидности ключей
  static bool get isMapKitKeyValid =>
      mapKitApiKey.isNotEmpty && mapKitApiKey.length > 10;
  static bool get isRoutingKeyValid =>
      routingApiKey.isNotEmpty && routingApiKey.length > 10;

  /// Статус конфигурации
  static String get configStatus {
    final mapKitStatus = isMapKitKeyValid ? '✅' : '❌';
    final routingStatus = isRoutingKeyValid ? '✅' : '❌';
    return 'MapKit: $mapKitStatus | Routing: $routingStatus';
  }
}
