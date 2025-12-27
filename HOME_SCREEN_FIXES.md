# 🔧 Исправления для home_screen.dart

## ✅ Что уже работает правильно:

```dart
void _loadNearbyServices() async {
  // ✅ Использует реальный API через AutoServicesRepository
  final services = await AutoServicesRepository()
      .getNearestServices(lat: lat, lon: lon, radius: 10000);
}
```

## ❌ Что НЕ нужно менять:

Файл `home_screen.dart` **УЖЕ ПРАВИЛЬНО** работает с бэкендом! 

Он использует:
- `AutoServicesRepository().getNearestServices()` - загружает сервисы с API
- `_showServiceDetails()` - показывает детали сервиса
- Вся логика карты, навигации, маршрутов - это **клиентская логика**, она правильная

## 🎯 Что может вызывать ошибки:

### 1. Поля модели AutoServiceModel
Проверь что все поля используются правильно:
```dart
// ❌ Старый код (если есть):
service.imageUrl  // может быть null

// ✅ Новый код:
service.images.firstOrNull?.imageUrl  // используем список images
```

### 2. ID сервиса
```dart
// ✅ Правильно:
service.id  // это String (из модели)
```

### 3. Rating
```dart
// ✅ Используй геттер:
service.displayRating  // вместо service.rating
service.displayReviewCount  // вместо reviewCount
```

## 📝 Конкретные исправления:

### Исправление 1: Использование images вместо imageUrl
**Строка ~1126-1130:**
```dart
// ❌ Было:
if (service.imageUrl != null) {
  Image.network(service.imageUrl!, ...)
}

// ✅ Стало:
if (service.images.isNotEmpty) {
  Image.network(service.images.first.imageUrl ?? service.images.first.image, ...)
}
```

### Исправление 2: Использование displayRating
**Строка ~1145:**
```dart
// ❌ Было:
Text('${'rating'.tr()}: ${service.rating}'),

// ✅ Стало:
Text('${'rating'.tr()}: ${service.displayRating.toStringAsFixed(1)} (${service.displayReviewCount} отзывов)'),
```

### Исправление 3: Рабочие часы
**Строка ~1147:**
```dart
// ❌ Было:
Text('${'working_hours'.tr()}: ${service.workingHours}'),

// ✅ Стало:
if (service.startTime != null && service.endTime != null)
  Text('${'working_hours'.tr()}: ${service.startTime} - ${service.endTime}'),
```

## 🔍 Проверь эти строки:

1. **Строка ~1126** - отображение изображения сервиса
2. **Строка ~1145** - отображение рейтинга
3. **Строка ~1147** - отображение рабочих часов
4. **Строка ~1149** - отображение телефона

## 💡 Рекомендации:

### 1. Обработка пустых данных
```dart
// Добавь проверки:
if (service.phone?.isNotEmpty ?? false) {
  Text('${'phone'.tr()}: ${service.phone}'),
}
```

### 2. Кэширование изображений
```dart
// Используй cached_network_image:
if (service.images.isNotEmpty) {
  CachedNetworkImage(
    imageUrl: service.images.first.imageUrl ?? service.images.first.image,
    placeholder: (context, url) => CircularProgressIndicator(),
    errorWidget: (context, url, error) => Icon(Icons.business),
  ),
}
```

## 🚀 Итог:

Файл **почти готов**! Нужны только **мелкие правки** для использования новых полей модели.

Основная логика работы с API **УЖЕ ПРАВИЛЬНАЯ** ✅

---

Хочешь, чтобы я показал конкретные строки кода для замены?
