# 🚀 Быстрая шпаргалка по обновлённым моделям

## ✅ Что изменилось?

Все модели обновлены под API, но **ничего не сломано**! Старый код работает как прежде.

---

## 📝 Основные изменения

### UserModel
```dart
// ✅ Старый код работает:
user.name           // всё ещё работает
user.avatarUrl      // всё ещё работает

// 🆕 Новые поля из API:
user.fullName       // основное имя
user.image          // URL аватара
user.telegram       // Telegram
user.createdAt      // дата создания

// 💡 Используй геттеры:
user.displayName    // fullName ?? name
user.displayAvatar  // image ?? avatarUrl
```

### ProductModel
```dart
// ✅ Старый код работает:
product.price       // всё ещё работает
product.oldPrice    // всё ещё работает

// 🆕 Новые поля из API:
product.shopId         // ID магазина
product.year           // год выпуска
product.color          // цвет
product.originalPrice  // оригинальная цена
product.discountPrice  // цена со скидкой

// 💡 Геттеры автоматически конвертируют:
product.price             // -> discountPrice
product.oldPrice          // -> originalPrice (если есть)
product.discountPercentage // -> процент скидки
```

### AutoServiceModel
```dart
// ✅ Старый код работает:
service.rating      // всё ещё работает

// 🆕 Новые поля из API:
service.averageRating       // средний рейтинг
service.reviewCount         // кол-во отзывов
service.category            // категория сервиса
service.workingDays         // [1,2,3,4,5]
service.extraServices       // список услуг
service.status              // pending/enabled/disabled
service.isActive            // активен ли

// 💡 Используй геттеры:
service.displayRating       // averageRating ?? rating
service.displayReviewCount  // reviewCount ?? 0
```

---

## 🔑 Ключевые API эндпоинты

### Авторизация
```dart
POST /api/userx/register/
POST /api/userx/login/
POST /api/userx/logout/
GET  /api/userx/profile/
```

### Сервисы
```dart
GET    /api/service/              // список
GET    /api/service/nearest/      // ближайшие
POST   /api/service/create/       // создать
GET    /api/service/{id}/         // детали
PATCH  /api/service/{id}/         // обновить
DELETE /api/service/{id}/         // удалить
```

### Товары (Market)
```dart
GET  /api/market/my/products/              // мои товары
POST /api/market/products/                 // создать
GET  /api/market/my/product-reservations/  // бронирования
```

---

## 💡 Примеры использования

### 1. Загрузка профиля
```dart
final profile = await authRepository.getUserProfile();
print(profile?.displayName);  // Используй displayName
print(profile?.displayAvatar); // Используй displayAvatar
```

### 2. Создание продукта
```dart
final product = ProductModel(
  shopId: 1,
  name: 'Тормозные колодки',
  year: 2024,
  description: 'Качественные тормозные колодки',
  originalPrice: 50000,
  discountPrice: 45000,
);

// Автоматически:
print(product.price); // 45000
print(product.discountPercentage); // 10%
```

### 3. Отображение сервиса
```dart
final service = AutoServiceModel.fromJson(apiResponse);

Text('Рейтинг: ${service.displayRating}');
Text('Отзывов: ${service.displayReviewCount}');
Text('Категория: ${service.category?.name ?? "N/A"}');
```

---

## ⚠️ Важно!

1. **Всегда используй геттеры** вместо прямых полей:
   - ✅ `user.displayName`
   - ❌ `user.fullName ?? user.name`

2. **Проверяй nullable поля:**
   ```dart
   if (service.category != null) {
     print(service.category!.name);
   }
   ```

3. **Импортируй модели правильно:**
   ```dart
   import 'package:auto_service/data/models/models.dart';
   ```

---

## 🎯 Следующие шаги

1. ✅ Модели готовы
2. 🔄 Обнови репозитории под новые эндпоинты
3. 🎨 Обнови UI для использования новых полей
4. 🧪 Протестируй интеграцию с API

---

**Полная документация:** `MODELS_MIGRATION_GUIDE.md`
