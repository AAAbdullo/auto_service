# 🔄 API Models Migration Guide

## ✅ Что было обновлено

### 1. UserModel
**Новые поля из API:**
- `id` (int) - ID пользователя
- `fullName` (String) - полное имя (вместо name)
- `image` (String) - URL аватара (вместо avatarUrl)
- `telegram` (String) - Telegram username
- `createdAt` (DateTime) - дата создания
- `updatedAt` (DateTime) - дата обновления
- `isSuperuser` (bool) - флаг админа

**Сохранены для обратной совместимости:**
- `name`, `email`, `avatarUrl`

**Удобные геттеры:**
```dart
user.displayName  // Возвращает fullName ?? name ?? 'User'
user.displayAvatar  // Возвращает image ?? avatarUrl
```

---

### 2. ProductModel
**Новые поля из API:**
- `id` (int) - ID продукта
- `shopId` (int) - ID магазина
- `categoryId` (int) - ID категории
- `year` (int) - год выпуска
- `color` (String) - цвет
- `model` (String) - модель
- `features` (String) - характеристики (текст)
- `advantages` (String) - преимущества (текст)
- `originalPrice` (double) - оригинальная цена
- `discountPrice` (double) - цена со скидкой

**Сохранены для обратной совместимости:**
- Все старые поля (`nameKey`, `imageUrl`, `rating`, и т.д.)

**Удобные геттеры:**
```dart
product.price  // Возвращает discountPrice
product.oldPrice  // Возвращает originalPrice если есть скидка
product.discountPercentage  // Процент скидки
```

---

### 3. AutoServiceModel
**Новые поля из API:**
- `averageRating` (double) - средний рейтинг
- `reviewCount` (int) - количество отзывов
- `verifiedReviewCount` (int) - количество подтвержденных отзывов
- `ratingBreakdown` (Map) - разбивка рейтинга
- `detailedRatings` (Map) - детальные рейтинги
- `category` (ServiceCategory) - категория сервиса
- `status` (String) - статус (pending/enabled/disabled)
- `startTime` (String) - время начала работы
- `endTime` (String) - время окончания работы
- `workingDays` (List<int>) - рабочие дни [1,2,3,4,5]
- `extraServices` (List<ExtraService>) - дополнительные услуги
- `isActive` (bool) - активен ли сервис
- `createdAt` (DateTime) - дата создания
- `telegram` (String) - Telegram
- `distance` (double) - расстояние (из nearest query)

**Сохранены для обратной совместимости:**
- `rating`, `services`, `workingHours`

**Удобные геттеры:**
```dart
service.displayRating  // Возвращает averageRating ?? rating
service.displayReviewCount  // Возвращает reviewCount ?? 0
```

---

### 4. Новые модели
**ShopModel** - модель магазина запчастей
**ProductReservationModel** - модель бронирования товара

---

## 🔧 Как использовать

### Пример 1: UserModel
```dart
// Старый код продолжает работать:
final user = UserModel(phone: '+998901234567', name: 'John');
print(user.name); // ✅ работает

// Новый код с API:
final userFromApi = UserModel.fromJson(apiResponse);
print(userFromApi.displayName); // Использует fullName или name
print(userFromApi.displayAvatar); // Использует image или avatarUrl
```

### Пример 2: ProductModel
```dart
// Старый код:
final product = ProductModel(
  id: '1',
  name: 'Тормозные колодки',
  price: 50000,
  // ...
);

// Новый код с API:
final productFromApi = ProductModel.fromJson(apiResponse);
print(productFromApi.price); // discountPrice
print(productFromApi.oldPrice); // originalPrice (если есть)
print(productFromApi.discountPercentage); // Процент скидки
```

### Пример 3: AutoServiceModel
```dart
// API response парсится автоматически:
final service = AutoServiceModel.fromJson(apiResponse);

print(service.displayRating); // Актуальный рейтинг
print(service.category?.name); // Название категории
print(service.workingDays); // [1, 2, 3, 4, 5]
print(service.extraServices); // Список дополнительных услуг
```

---

## ⚠️ Важные изменения

### 1. UserModel
- **Было:** `name` - для имени пользователя
- **Стало:** `fullName` - основное поле, `name` - для совместимости
- **Действие:** Используй `displayName` геттер

### 2. ProductModel
- **Было:** `price` и `oldPrice`
- **Стало:** `originalPrice` и `discountPrice`
- **Действие:** Используй `price` и `oldPrice` геттеры

### 3. AutoServiceModel
- **Было:** `rating` (один общий)
- **Стало:** `averageRating`, `detailedRatings`, `ratingBreakdown`
- **Действие:** Используй `displayRating` геттер

---

## 🚀 Что делать дальше?

1. ✅ Модели обновлены и обратно совместимы
2. 🔄 Постепенно обновляй UI код для использования новых полей
3. 📝 Обнови репозитории для работы с новыми эндпоинтами

---

## 📦 Новые эндпоинты API

### User Management
- `POST /api/userx/register/` - регистрация
- `POST /api/userx/login/` - вход
- `POST /api/userx/logout/` - выход
- `GET /api/userx/profile/` - получить профиль
- `PATCH /api/userx/upload-image/` - загрузить аватар

### Auto Services
- `GET /api/service/` - список сервисов
- `GET /api/service/nearest/` - ближайшие сервисы
- `POST /api/service/create/` - создать сервис
- `GET /api/service/{id}/` - детали сервиса
- `PATCH /api/service/{id}/` - обновить сервис
- `DELETE /api/service/{id}/` - удалить сервис
- `POST /api/service/{service_id}/images/` - загрузить изображение

### Reviews
- `GET /api/service/{service_id}/reviews/` - отзывы сервиса
- `POST /api/service/reviews/` - создать отзыв
- `GET /api/service/{service_id}/rating-stats/` - статистика рейтинга

### Products (Market)
- `GET /api/market/my/products/` - мои товары
- `POST /api/market/products/` - создать товар
- `GET /api/market/my/product-reservations/` - мои бронирования

### Shop
- `POST /api/market/shops/` - создать магазин
- `GET /api/market/my/shop/` - мой магазин

---

## 💡 Полезные советы

1. **Всегда используй геттеры** (`displayName`, `displayRating`) вместо прямого доступа к полям
2. **Проверяй nullable поля** перед использованием
3. **Используй copyWith()** для создания копий с изменениями
4. **Импортируй модели через** `import 'package:auto_service/data/models/models.dart';`

---

Создано: ${DateTime.now()}
