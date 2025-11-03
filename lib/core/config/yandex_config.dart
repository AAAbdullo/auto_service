/// Конфигурация API ключей Яндекс сервисов
class YandexConfig {
  /// API ключ для MapKit – мобильный SDK (карты, геолокация, UI)
  /// Используется для:
  /// - Отображения карт
  /// - Встроенного индикатора пользователя
  /// - Управления камерой карты
  /// - Маркеров и объектов на карте
  static const String mapKitApiKey = '20a40c6c-d27c-46b6-b96a-b4b6a4cb47ba';
  
  /// API ключ для Матрица Расстояний и Построение Маршрута
  /// Используется для:
  /// - Построения маршрутов через Router API
  /// - Получения детальной геометрии маршрутов
  /// - Расчета времени и расстояния
  /// - Информации о маневрах
  static const String routingApiKey = 'bbbd0c5d-648c-4efa-bf9f-3b6ed20afa71';
  
  /// Базовый URL для Router API
  static const String routingBaseUrl = 'https://api.routing.yandex.net/v2/route';
  
  /// Проверка валидности ключей
  static bool get isMapKitKeyValid => mapKitApiKey.isNotEmpty && mapKitApiKey.length > 10;
  static bool get isRoutingKeyValid => routingApiKey.isNotEmpty && routingApiKey.length > 10;
  
  /// Статус конфигурации
  static String get configStatus {
    final mapKitStatus = isMapKitKeyValid ? '✅' : '❌';
    final routingStatus = isRoutingKeyValid ? '✅' : '❌';
    return 'MapKit: $mapKitStatus | Routing: $routingStatus';
  }
}
