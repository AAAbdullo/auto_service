# Avto Service API - Документация

## Общая информация

**Версия API:** 1.0.0  
**Базовый URL:** `http://10.10.0.60:8866`  
**Формат данных:** JSON  
**Аутентификация:** JWT Bearer Token

---

## Аутентификация

API использует JWT (JSON Web Token) для аутентификации. После успешного входа вы получите `access` и `refresh` токены.

### Использование токена

Добавьте токен в заголовок запроса:
```
Authorization: Bearer <ваш_access_token>
```

---

## 1. Управление пользователями

### 1.1 Регистрация пользователя
**POST** `/api/userx/register/`

Создание нового аккаунта пользователя.

**Тело запроса:**
```json
{
  "full_name": "Иван Иванов",
  "phone": "+998901234567",
  "password": "securePassword123",
  "telegram": "@username"
}
```

**Ответ (201):**
```json
{
  "id": 1,
  "full_name": "Иван Иванов",
  "phone": "+998901234567",
  "telegram": "@username"
}
```

---

### 1.2 Вход пользователя
**POST** `/api/userx/login/`

Аутентификация пользователя и получение токенов.

**Тело запроса:**
```json
{
  "phone": "+998901234567",
  "password": "securePassword123"
}
```

**Ответ (200):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

---

### 1.3 Выход пользователя
**POST** `/api/userx/logout/`

Выход из системы и добавление refresh токена в черный список.

**Требуется аутентификация:** ✅

**Тело запроса:**
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Ответ (200):**
```json
{
  "message": "Successfully logged out"
}
```

---

### 1.4 Получить профиль текущего пользователя
**GET** `/api/userx/profile/`

**Требуется аутентификация:** ✅

**Ответ (200):**
```json
{
  "id": 1,
  "full_name": "Иван Иванов",
  "phone": "+998901234567",
  "image": "http://10.10.0.60:8866/media/users/avatar.jpg",
  "telegram": "@username",
  "created_at": "2024-01-15T10:30:00Z",
  "update_at": "2024-01-20T15:45:00Z",
  "is_superuser": false
}
```

---

### 1.5 Загрузить изображение профиля
**PATCH** `/api/userx/upload-image/`

**Требуется аутентификация:** ✅  
**Content-Type:** `multipart/form-data`

**Тело запроса:**
```
image: <файл изображения>
```

**Ответ (200):**
```json
{
  "id": 1,
  "image": "http://10.10.0.60:8866/media/users/avatar.jpg"
}
```

---

### 1.6 Список всех пользователей (Admin)
**GET** `/api/userx/`

**Требуется аутентификация:** ✅  
**Требуется права администратора**

**Параметры запроса:**
- `page` - номер страницы
- `search` - поисковый запрос
- `ordering` - поле для сортировки

**Ответ (200):**
```json
{
  "count": 100,
  "next": "http://10.10.0.60:8866/api/userx/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "full_name": "Иван Иванов",
      "phone": "+998901234567",
      "image": null,
      "telegram": "@username",
      "created_at": "2024-01-15T10:30:00Z",
      "update_at": "2024-01-20T15:45:00Z",
      "is_superuser": false
    }
  ]
}
```

---

### 1.7 Детали пользователя
**GET** `/api/userx/{id}/`

**Требуется аутентификация:** ✅

---

### 1.8 Обновить пользователя
**PATCH** `/api/userx/{id}/`

**Требуется аутентификация:** ✅

**Тело запроса:**
```json
{
  "full_name": "Новое имя",
  "telegram": "@new_username"
}
```

---

### 1.9 Удалить пользователя
**DELETE** `/api/userx/{id}/`

**Требуется аутентификация:** ✅

**Ответ (204):** No Content

---

## 2. Управление автосервисами

### 2.1 Список автосервисов
**GET** `/api/service/`

Получение списка активных автосервисов с фильтрацией.

**Требуется аутентификация:** ❌ (опционально)

**Параметры запроса:**
- `page` - номер страницы
- `search` - поисковый запрос
- `ordering` - сортировка
- `category` - фильтр по категории (ID)
- `name` - фильтр по имени
- `address` - фильтр по адресу

**Ответ (200):**
```json
{
  "count": 50,
  "next": "http://10.10.0.60:8866/api/service/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "AutoFix Center",
      "description": "Профессиональный ремонт автомобилей",
      "address": "ул. Мирабадская, 15",
      "phone_number": "+998901234567",
      "start_time": "09:00:00",
      "end_time": "18:00:00",
      "working_days": [1, 2, 3, 4, 5],
      "category": {
        "id": 1,
        "name": "Ремонт двигателя",
        "slug": "engine-repair"
      },
      "owner": "Иван Иванов",
      "telegram": "@autofix_center",
      "status": "enabled",
      "is_active": true,
      "created_at": "2024-01-10T08:00:00Z",
      "images": [
        {
          "id": 1,
          "image": "http://10.10.0.60:8866/media/services/image1.jpg",
          "image_url": "http://10.10.0.60:8866/media/services/image1.jpg",
          "created_at": "2024-01-10T08:30:00Z",
          "is_active": true
        }
      ],
      "distance": 2.5,
      "lat": 41.2995,
      "lon": 69.2401,
      "average_rating": 4.5,
      "review_count": 25
    }
  ]
}
```

---

### 2.2 Создать автосервис
**POST** `/api/service/create/`

**Требуется аутентификация:** ✅

**Тело запроса:**
```json
{
  "name": "AutoFix Center",
  "description": "Профессиональный ремонт автомобилей",
  "address": "ул. Мирабадская, 15",
  "phone_number": "+998901234567",
  "start_time": "09:00:00",
  "end_time": "18:00:00",
  "working_days": [1, 2, 3, 4, 5],
  "category": 1,
  "lat": 41.2995,
  "lon": 69.2401,
  "is_active": true
}
```

**Ответ (201):**
```json
{
  "name": "AutoFix Center",
  "description": "Профессиональный ремонт автомобилей",
  "address": "ул. Мирабадская, 15",
  "phone_number": "+998901234567",
  "start_time": "09:00:00",
  "end_time": "18:00:00",
  "working_days": [1, 2, 3, 4, 5],
  "category": 1,
  "is_active": true
}
```

---

### 2.3 Детали автосервиса
**GET** `/api/service/{id}/`

**Требуется аутентификация:** ❌ (опционально)

**Ответ (200):**
```json
{
  "id": 1,
  "name": "AutoFix Center",
  "description": "Профессиональный ремонт автомобилей",
  "address": "ул. Мирабадская, 15",
  "phone_number": "+998901234567",
  "start_time": "09:00:00",
  "end_time": "18:00:00",
  "working_days": [1, 2, 3, 4, 5],
  "category": {
    "id": 1,
    "name": "Ремонт двигателя",
    "slug": "engine-repair"
  },
  "lat": 41.2995,
  "lon": 69.2401,
  "owner": "Иван Иванов",
  "telegram": "@autofix_center",
  "status": "enabled",
  "is_active": true,
  "created_at": "2024-01-10T08:00:00Z",
  "images": [...],
  "extra_services": [
    {
      "id": 1,
      "name": "Бесплатная диагностика"
    }
  ],
  "average_rating": 4.5,
  "rating_breakdown": {
    "5": 15,
    "4": 8,
    "3": 2,
    "2": 0,
    "1": 0
  },
  "detailed_ratings": {
    "quality": 4.6,
    "price": 4.3,
    "location": 4.7,
    "staff": 4.5
  },
  "review_count": 25,
  "verified_review_count": 20
}
```

---

### 2.4 Обновить автосервис
**PATCH** `/api/service/{id}/`

**Требуется аутентификация:** ✅  
**Только владелец может обновлять**

**Тело запроса:**
```json
{
  "description": "Обновленное описание",
  "phone_number": "+998901234568"
}
```

---

### 2.5 Удалить автосервис
**DELETE** `/api/service/{id}/`

**Требуется аутентификация:** ✅  
**Только владелец может удалить**

**Ответ (204):** No Content

---

### 2.6 Мои автосервисы
**GET** `/api/service/my/`

Получить список автосервисов текущего пользователя.

**Требуется аутентификация:** ✅

**Параметры запроса:**
- `page` - номер страницы
- `search` - поиск
- `ordering` - сортировка

---

### 2.7 Ближайшие автосервисы
**GET** `/api/service/nearest/`

Поиск автосервисов рядом с указанными координатами.

**Требуется аутентификация:** ❌ (опционально)

**Обязательные параметры:**
- `lat` - широта (например: 41.2995)
- `lon` - долгота (например: 69.2401)

**Опциональные параметры:**
- `radius` - радиус поиска в метрах (по умолчанию: 5000)
- `category` - фильтр по категории
- `page` - номер страницы
- `page_size` - количество результатов (по умолчанию: 20, макс: 100)

**Пример запроса:**
```
GET /api/service/nearest/?lat=41.2995&lon=69.2401&radius=3000&category=1
```

**Ответ (200):**
```json
{
  "count": 10,
  "next": null,
  "previous": null,
  "results": [...],
  "radius": 3000,
  "location": {
    "lat": 41.2995,
    "lon": 69.2401
  }
}
```

---

## 3. Управление изображениями сервиса

### 3.1 Загрузить изображение сервиса
**POST** `/api/service/{service_id}/images/`

**Требуется аутентификация:** ✅  
**Только владелец сервиса**  
**Content-Type:** `multipart/form-data`

**Тело запроса:**
```
image: <файл изображения>
```

**Ответ (201):**
```json
{
  "id": 1,
  "image": "http://10.10.0.60:8866/media/services/image1.jpg",
  "image_url": "http://10.10.0.60:8866/media/services/image1.jpg",
  "created_at": "2024-01-10T08:30:00Z",
  "is_active": true
}
```

---

### 3.2 Удалить изображение сервиса
**DELETE** `/api/service/{service_id}/images/`

**Требуется аутентификация:** ✅  
**Только владелец сервиса**

**Ответ (200):**
```json
{
  "message": "Image deleted successfully"
}
```

---

## 4. Управление отзывами

### 4.1 Список отзывов сервиса
**GET** `/api/service/{service_id}/reviews/`

**Требуется аутентификация:** ❌ (опционально)

**Параметры запроса:**
- `page` - номер страницы
- `ordering` - сортировка

**Ответ (200):**
```json
{
  "count": 25,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "service": 1,
      "service_name": "AutoFix Center",
      "user": 5,
      "user_name": "Петр Петров",
      "title": "Отличный сервис!",
      "comment": "Быстро и качественно отремонтировали двигатель",
      "overall_rating": 5,
      "quality_rating": 5,
      "price_rating": 4,
      "location_rating": 5,
      "staff_rating": 5,
      "is_verified": true,
      "average_detailed_rating": "4.75",
      "likes_count": 10,
      "dislikes_count": 1,
      "user_like": true,
      "has_response": true,
      "created_at": "2024-01-15T14:30:00Z"
    }
  ]
}
```

---

### 4.2 Создать отзыв
**POST** `/api/service/reviews/`

**Требуется аутентификация:** ✅

**Тело запроса:**
```json
{
  "service": 1,
  "title": "Отличный сервис!",
  "comment": "Быстро и качественно отремонтировали двигатель",
  "overall_rating": 5,
  "quality_rating": 5,
  "price_rating": 4,
  "location_rating": 5,
  "staff_rating": 5,
  "is_verified": true,
  "review_category_ids": [1, 2]
}
```

**Примечание:** Пользователь может создать только один отзыв на сервис.

**Ответ (201):**
```json
{
  "service": 1,
  "title": "Отличный сервис!",
  "comment": "Быстро и качественно отремонтировали двигатель",
  "overall_rating": 5,
  "quality_rating": 5,
  "price_rating": 4,
  "location_rating": 5,
  "staff_rating": 5,
  "is_verified": true
}
```

---

### 4.3 Детали отзыва
**GET** `/api/service/reviews/{id}/`

**Требуется аутентификация:** ❌ (опционально)

**Ответ (200):**
```json
{
  "id": 1,
  "service": 1,
  "service_name": "AutoFix Center",
  "user": 5,
  "user_name": "Петр Петров",
  "title": "Отличный сервис!",
  "comment": "Быстро и качественно отремонтировали двигатель",
  "overall_rating": 5,
  "quality_rating": 5,
  "price_rating": 4,
  "location_rating": 5,
  "staff_rating": 5,
  "is_verified": true,
  "is_public": true,
  "is_flagged": false,
  "flagged_reason": "",
  "review_categories": [
    {
      "id": 1,
      "name": "Профессионализм",
      "description": "Профессиональное обслуживание",
      "is_active": true
    }
  ],
  "responses": [
    {
      "id": 1,
      "review": 1,
      "owner": 2,
      "owner_name": "Иван Иванов",
      "response_text": "Спасибо за отзыв!",
      "created_at": "2024-01-15T15:00:00Z",
      "updated_at": "2024-01-15T15:00:00Z"
    }
  ],
  "average_detailed_rating": "4.75",
  "likes_count": 10,
  "dislikes_count": 1,
  "user_like": true,
  "created_at": "2024-01-15T14:30:00Z",
  "updated_at": "2024-01-15T14:30:00Z"
}
```

---

### 4.4 Обновить отзыв
**PATCH** `/api/service/reviews/{id}/`

**Требуется аутентификация:** ✅  
**Только автор может обновлять**

**Тело запроса:**
```json
{
  "comment": "Обновленный комментарий",
  "overall_rating": 4
}
```

---

### 4.5 Удалить отзыв
**DELETE** `/api/service/reviews/{id}/`

**Требуется аутентификация:** ✅  
**Только автор может удалить**

**Ответ (204):** No Content

---

### 4.6 Лайк/дизлайк отзыва
**GET** `/api/service/reviews/like/`

**Требуется аутентификация:** ✅

**Параметры запроса:**
- `review_id` - ID отзыва (обязательно)
- `is_like` - true для лайка, false для дизлайка (по умолчанию: true)

**Пример запроса:**
```
GET /api/service/reviews/like/?review_id=1&is_like=true
```

**Ответ (200):**
```json
{
  "id": 1,
  "user": 5,
  "user_name": "Петр Петров",
  "is_like": true,
  "created_at": "2024-01-15T16:00:00Z"
}
```

---

### 4.7 Ответить на отзыв
**POST** `/api/service/reviews/response/`

**Требуется аутентификация:** ✅  
**Только владелец сервиса**

**Тело запроса:**
```json
{
  "review": 1,
  "response_text": "Спасибо за ваш отзыв! Рады, что вы остались довольны."
}
```

**Ответ (201):**
```json
{
  "id": 1,
  "review": 1,
  "owner": 2,
  "owner_name": "Иван Иванов",
  "response_text": "Спасибо за ваш отзыв! Рады, что вы остались довольны.",
  "created_at": "2024-01-15T15:00:00Z",
  "updated_at": "2024-01-15T15:00:00Z"
}
```

---

### 4.8 Список категорий отзывов
**GET** `/api/service/reviews/categories/`

**Требуется аутентификация:** ❌ (опционально)

**Параметры запроса:**
- `page` - номер страницы
- `search` - поиск
- `ordering` - сортировка

**Ответ (200):**
```json
{
  "count": 10,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Профессионализм",
      "description": "Профессиональное обслуживание",
      "is_active": true
    },
    {
      "id": 2,
      "name": "Быстрота",
      "description": "Быстрое выполнение работ",
      "is_active": true
    }
  ]
}
```

---

### 4.9 Статистика рейтингов сервиса
**GET** `/api/service/{service_id}/rating-stats/`

**Требуется аутентификация:** ❌ (опционально)

**Ответ (200):**
```json
{
  "service_id": 1,
  "average_rating": 4.5,
  "total_reviews": 25,
  "rating_breakdown": {
    "5": 15,
    "4": 8,
    "3": 2,
    "2": 0,
    "1": 0
  },
  "detailed_ratings": {
    "quality": 4.6,
    "price": 4.3,
    "location": 4.7,
    "staff": 4.5
  }
}
```

---

## 5. Платежи

### 5.1 Записать наличный платеж
**POST** `/api/service/payments/cash/`

**Требуется аутентификация:** ✅  
**Только владелец сервиса**

**Тело запроса:**
```json
{
  "service": 1,
  "amount": "150000.00",
  "note": "Оплата за ремонт двигателя"
}
```

**Ответ (201):**
```json
{
  "id": 1,
  "service": 1,
  "amount": "150000.00",
  "paid_at": "2024-01-15T16:30:00Z",
  "note": "Оплата за ремонт двигателя"
}
```

---

## 6. Магазин запчастей

### 6.1 Создать магазин
**POST** `/api/market/shops/`

**Требуется аутентификация:** ✅

**Тело запроса:**
```json
{
  "name": "AutoParts Shop",
  "address": "ул. Навои, 25",
  "phone": "+998901234567",
  "description": "Магазин автозапчастей"
}
```

**Ответ (201):**
```json
{
  "id": 1,
  "name": "AutoParts Shop",
  "address": "ул. Навои, 25",
  "phone": "+998901234567",
  "description": "Магазин автозапчастей"
}
```

---

### 6.2 Обновить магазин
**PUT/PATCH** `/api/market/shops/{id}/`

**Требуется аутентификация:** ✅

---

### 6.3 Мой магазин
**GET** `/api/market/my/shop/`

**Требуется аутентификация:** ✅

---

### 6.4 Создать товар
**POST** `/api/market/products/`

**Требуется аутентификация:** ✅

**Тело запроса:**
```json
{
  "shop": 1,
  "category": 1,
  "name": "Масляный фильтр",
  "year": 2024,
  "description": "Оригинальный масляный фильтр",
  "color": "Черный",
  "model": "OF-2024",
  "features": "Высокое качество фильтрации",
  "advantages": "Длительный срок службы",
  "original_price": "50000.00",
  "discount_price": "45000.00"
}
```

**Ответ (201):**
```json
{
  "id": 1,
  "shop": 1,
  "category": 1,
  "name": "Масляный фильтр",
  "year": 2024,
  "description": "Оригинальный масляный фильтр",
  "color": "Черный",
  "model": "OF-2024",
  "features": "Высокое качество фильтрации",
  "advantages": "Длительный срок службы",
  "original_price": "50000.00",
  "discount_price": "45000.00"
}
```

---

### 6.5 Список моих товаров
**GET** `/api/market/my/products/`

**Требуется аутентификация:** ✅

**Параметры запроса:**
- `page` - номер страницы
- `search` - поиск
- `ordering` - сортировка

---

### 6.6 Обновить товар
**PUT/PATCH** `/api/market/products/{id}/`

**Требуется аутентификация:** ✅

---

### 6.7 Удалить товар
**DELETE** `/api/market/products/{id}/delete/`

**Требуется аутентификация:** ✅

**Ответ (204):** No Content

---

### 6.8 Мои бронирования товаров
**GET** `/api/market/my/product-reservations/`

**Требуется аутентификация:** ✅

**Параметры запроса:**
- `page` - номер страницы
- `search` - поиск
- `ordering` - сортировка

**Ответ (200):**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "product": {
        "id": 1,
        "shop": 1,
        "category": 1,
        "name": "Масляный фильтр",
        "year": 2024,
        "description": "Оригинальный масляный фильтр",
        "color": "Черный",
        "model": "OF-2024",
        "features": "Высокое качество фильтрации",
        "advantages": "Длительный срок службы",
        "original_price": "50000.00",
        "discount_price": "45000.00"
      },
      "status": "pending",
      "created_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

---

### 6.9 Изменить статус бронирования
**PATCH** `/api/market/product-reservations/{id}/status/`

**Требуется аутентификация:** ✅

**Тело запроса:**
```json
{
  "status": "confirmed"
}
```

**Возможные статусы:**
- `pending` - В ожидании
- `confirmed` - Подтверждено
- `cancelled` - Отменено

---

## 7. Системные эндпоинты

### 7.1 Проверка здоровья API
**GET** `/`

**Требуется аутентификация:** ❌ (опционально)

**Ответ (200):**
```json
{
  "ok": true
}
```

---

## Коды ошибок

| Код | Описание |
|-----|----------|
| 200 | Успешный запрос |
| 201 | Ресурс создан |
| 204 | Успешно, нет содержимого |
| 400 | Неверный запрос |
| 401 | Не авторизован |
| 403 | Доступ запрещен |
| 404 | Не найдено |
| 500 | Внутренняя ошибка сервера |

---

## Примеры использования

### Пример 1: Регистрация и создание автосервиса

```bash
# 1. Регистрация пользователя
curl -X POST http://10.10.0.60:8866/api/userx/register/ \
  -H "Content-Type: application/json" \