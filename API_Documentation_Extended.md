  -d '{
    "full_name": "Иван Иванов",
    "phone": "+998901234567",
    "password": "securePassword123",
    "telegram": "@username"
  }'

# 2. Вход
curl -X POST http://10.10.0.60:8866/api/userx/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+998901234567",
    "password": "securePassword123"
  }'

# Ответ: {"access": "TOKEN", "refresh": "REFRESH_TOKEN"}

# 3. Создание автосервиса
curl -X POST http://10.10.0.60:8866/api/service/create/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "name": "AutoFix Center",
    "description": "Профессиональный ремонт",
    "address": "ул. Мирабадская, 15",
    "phone_number": "+998901234567",
    "start_time": "09:00:00",
    "end_time": "18:00:00",
    "working_days": [1, 2, 3, 4, 5],
    "category": 1,
    "lat": 41.2995,
    "lon": 69.2401,
    "is_active": true
  }'
```

### Пример 2: Поиск ближайших автосервисов

```bash
curl -X GET "http://10.10.0.60:8866/api/service/nearest/?lat=41.2995&lon=69.2401&radius=5000&category=1"
```

### Пример 3: Создание отзыва

```bash
curl -X POST http://10.10.0.60:8866/api/service/reviews/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "service": 1,
    "title": "Отличный сервис!",
    "comment": "Быстро и качественно отремонтировали",
    "overall_rating": 5,
    "quality_rating": 5,
    "price_rating": 4,
    "location_rating": 5,
    "staff_rating": 5,
    "is_verified": true,
    "review_category_ids": [1, 2]
  }'
```

---

## Рейтинговая система

### Типы оценок (1-5 звезд):

1. **overall_rating** - Общая оценка
2. **quality_rating** - Качество услуг
3. **price_rating** - Соотношение цены и качества
4. **location_rating** - Удобство расположения
5. **staff_rating** - Профессионализм персонала

### Значения:
- 1 - Очень плохо (Very Poor)
- 2 - Плохо (Poor)
- 3 - Средне (Average)
- 4 - Хорошо (Good)
- 5 - Отлично (Excellent)

---

## Статусы

### Статус автосервиса:
- `pending` - Ожидает подтверждения
- `enabled` - Активен
- `disabled` - Отключен

### Статус бронирования товара:
- `pending` - В ожидании
- `confirmed` - Подтверждено
- `cancelled` - Отменено

---

## Рабочие дни (working_days)

Массив чисел от 1 до 7, где:
- 1 = Понедельник
- 2 = Вторник
- 3 = Среда
- 4 = Четверг
- 5 = Пятница
- 6 = Суббота
- 7 = Воскресенье

**Пример:** `[1, 2, 3, 4, 5]` = с понедельника по пятницу

---

## Пагинация

Все списки поддерживают пагинацию:

```json
{
  "count": 100,
  "next": "http://10.10.0.60:8866/api/service/?page=2",
  "previous": null,
  "results": [...]
}
```

**Параметры:**
- `page` - номер страницы (начиная с 1)
- `page_size` - количество элементов на странице

---

## Поиск и фильтрация

Большинство списков поддерживают:
- `search` - текстовый поиск
- `ordering` - сортировка (добавьте `-` для обратной сортировки, например: `-created_at`)
- Специфические фильтры для каждого эндпоинта

---

## Дополнительные примеры

### Python (requests)

```python
import requests

# Регистрация
response = requests.post(
    'http://10.10.0.60:8866/api/userx/register/',
    json={
        'full_name': 'Иван Иванов',
        'phone': '+998901234567',
        'password': 'securePassword123',
        'telegram': '@username'
    }
)
print(response.json())

# Вход
response = requests.post(
    'http://10.10.0.60:8866/api/userx/login/',
    json={
        'phone': '+998901234567',
        'password': 'securePassword123'
    }
)
tokens = response.json()
access_token = tokens['access']

# Получение профиля
headers = {'Authorization': f'Bearer {access_token}'}
response = requests.get(
    'http://10.10.0.60:8866/api/userx/profile/',
    headers=headers
)
print(response.json())

# Создание автосервиса
response = requests.post(
    'http://10.10.0.60:8866/api/service/create/',
    headers=headers,
    json={
        'name': 'AutoFix Center',
        'description': 'Профессиональный ремонт',
        'address': 'ул. Мирабадская, 15',
        'phone_number': '+998901234567',
        'start_time': '09:00:00',
        'end_time': '18:00:00',
        'working_days': [1, 2, 3, 4, 5],
        'category': 1,
        'lat': 41.2995,
        'lon': 69.2401,
        'is_active': True
    }
)
print(response.json())
```

### JavaScript (Fetch API)

```javascript
// Регистрация
const register = async () => {
  const response = await fetch('http://10.10.0.60:8866/api/userx/register/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      full_name: 'Иван Иванов',
      phone: '+998901234567',
      password: 'securePassword123',
      telegram: '@username'
    })
  });
  const data = await response.json();
  console.log(data);
};

// Вход
const login = async () => {
  const response = await fetch('http://10.10.0.60:8866/api/userx/login/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      phone: '+998901234567',
      password: 'securePassword123'
    })
  });
  const tokens = await response.json();
  localStorage.setItem('accessToken', tokens.access);
  return tokens.access;
};

// Получение ближайших сервисов
const getNearestServices = async (lat, lon) => {
  const response = await fetch(
    `http://10.10.0.60:8866/api/service/nearest/?lat=${lat}&lon=${lon}&radius=5000`
  );
  const data = await response.json();
  console.log(data);
};

// Создание отзыва
const createReview = async (serviceId, accessToken) => {
  const response = await fetch('http://10.10.0.60:8866/api/service/reviews/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`
    },
    body: JSON.stringify({
      service: serviceId,
      title: 'Отличный сервис!',
      comment: 'Быстро и качественно',
      overall_rating: 5,
      quality_rating: 5,
      price_rating: 4,
      location_rating: 5,
      staff_rating: 5,
      is_verified: true
    })
  });
  const data = await response.json();
  console.log(data);
};
```

---

## Обработка ошибок

### Пример ответа с ошибкой:

```json
{
  "detail": "Authentication credentials were not provided."
}
```

или

```json
{
  "phone": ["This field is required."],
  "password": ["This field may not be blank."]
}
```

### Рекомендации по обработке:

```python
try:
    response = requests.post(url, json=data)
    response.raise_for_status()  # Вызовет исключение для кодов 4xx/5xx
    return response.json()
except requests.exceptions.HTTPError as e:
    print(f"HTTP Error: {e}")
    print(f"Response: {e.response.json()}")
except requests.exceptions.RequestException as e:
    print(f"Request Error: {e}")
```

---

## FAQ

### Q: Как обновить access token?
A: Используйте refresh token для получения нового access token через эндпоинт обновления токенов (не документирован в текущей спецификации, но стандартно это `/api/token/refresh/`).

### Q: Сколько действителен access token?
A: Обычно access token действителен 5-15 минут, refresh token - несколько дней/недель. Проверьте настройки вашего сервера.

### Q: Можно ли загрузить несколько изображений для сервиса?
A: Да, вызывайте эндпоинт загрузки изображений несколько раз для каждого изображения.

### Q: Как удалить конкретное изображение?
A: В текущей спецификации эндпоинт удаления не принимает ID изображения. Уточните у разработчиков API, как указать конкретное изображение для удаления.

### Q: Можно ли получить список всех категорий автосервисов?
A: В документации нет отдельного эндпоинта для категорий, но они возвращаются вместе с данными автосервисов.

---

## Контакты и поддержка

Для получения дополнительной информации или помощи обратитесь к администратору API.

**Базовый URL:** http://10.10.0.60:8866  
**Версия документации:** 1.0.0  
**Дата последнего обновления:** 17 декабря 2024