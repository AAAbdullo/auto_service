# 🚗 Auto Service - Flutter приложение с картами

Приложение для поиска автосервисов и заправок с интерактивной картой и навигацией.

## ✨ Последнее обновление: Карта с навигацией ⭐

**Дата:** 19 октября 2025  
**Статус:** ✅ Production Ready

### 🎯 Новые возможности:

- 🗺️ **Интерактивная карта** с 15 автосервисами и 15 заправками
- 🛣️ **Построение маршрутов** прямо на карте Yandex
- 📱 **Интеграция с Google Maps** для навигации
- 🔍 **Поиск и фильтрация** по названию и рейтингу
- 📍 **Геолокация** с определением вашего местоположения
- 🎨 **Цветовые маркеры**: красные (сервисы), зелёные (заправки), синие (вы)

---

## 🚀 Быстрый старт

### Установка и запуск:

```bash
# 1. Клонируйте проект (если ещё не сделали)
git clone <repository-url>
cd auto_service

# 2. Установите зависимости
flutter clean
flutter pub get

# 3. Запустите приложение
flutter run
```

### Или просто:
```bash
flutter clean && flutter pub get && flutter run
```

---

## 📚 Документация

### 🌟 Начните здесь:

| Документ | Для кого | Время чтения |
|----------|----------|--------------|
| **[DOCS_INDEX.md](DOCS_INDEX.md)** | Навигация по всем документам | 2 мин |
| **[FINAL_SUMMARY.md](FINAL_SUMMARY.md)** ⭐ | Все - полный обзор | 10 мин |
| **[QUICK_TEST_GUIDE.md](QUICK_TEST_GUIDE.md)** ⚡ | Быстрое тестирование | 5 мин |
| **[VISUAL_GUIDE.md](VISUAL_GUIDE.md)** 🎨 | Визуальные инструкции | 5 мин |

### Полная документация:

- 📖 [MAP_UPDATE_GUIDE.md](MAP_UPDATE_GUIDE.md) - Подробное руководство
- 🔧 [CHANGELOG_MAP.md](CHANGELOG_MAP.md) - Технические изменения
- ✅ [UPDATE_COMPLETE.md](UPDATE_COMPLETE.md) - Отчёт о работе
- 🎯 [MAP_UPDATE_README.md](MAP_UPDATE_README.md) - Краткий обзор

---

## 🎮 Как использовать

### 1. Первый запуск
```
Откройте приложение → Разрешите геолокацию → Готово!
```

### 2. Просмотр на карте
- Нажмите **🔧** справа - увидите **красные круги** (автосервисы)
- Нажмите **⛽** справа - увидите **зелёные круги** (заправки)
- **Синий круг** - это вы!

### 3. Построение маршрута
```
Нажмите на круг → Откроется информация → 
Нажмите "Построить маршрут" → Появится синяя линия!
```

### 4. Навигация
- **На карте** - следуйте по синей линии
- **В Google Maps** - нажмите "Открыть карту"

---

## 🛠️ Технологии

### Основные технологии:
- **Flutter SDK** ^3.9.2
- **Dart** ^3.9.2

### Ключевые пакеты:
- **yandex_mapkit** ^4.2.1 - карты и маршруты
- **geolocator** ^13.0.1 - геолокация
- **url_launcher** ^6.2.5 - внешние ссылки
- **easy_localization** ^3.0.8 - локализация (RU/UZ)
- **provider** ^6.1.2 - state management

---

## 📱 Функции приложения

### ✅ Реализовано:

#### Карта и навигация:
- [x] Отображение автосервисов на карте (15 точек)
- [x] Отображение заправок на карте (15 точек)
- [x] Определение местоположения пользователя
- [x] Построение маршрутов на карте
- [x] Интеграция с Google Maps
- [x] Переключение между сервисами и заправками
- [x] Цветные маркеры для разных типов

#### Интерфейс:
- [x] Поиск по названию
- [x] Фильтры по рейтингу
- [x] Детальная информация о точках
- [x] Темная и светлая темы
- [x] Двуязычность (Русский/Узбекский)

#### Другие разделы:
- [x] Авторизация и регистрация
- [x] Магазин автозапчастей
- [x] Корзина покупок
- [x] Бронирование деталей
- [x] История заказов
- [x] Профиль пользователя
- [x] Настройки приложения

---

## 🎨 Цветовая схема

| Цвет | Элемент | Значение |
|------|---------|----------|
| 🔴 Красный | Круг 30м | Автосервис |
| 🟢 Зелёный | Круг 30м | Заправка |
| 🔵 Синий | Круг 50м | Ваше местоположение |
| 🔵 Синяя линия | Полилиния | Построенный маршрут |

---

## 📊 Структура проекта

```
lib/
├── core/                   # Ядро приложения
│   ├── constants/         # Константы, цвета, строки
│   ├── theme/            # Темы приложения
│   └── utils/            # Утилиты
│
├── data/                  # Слой данных
│   ├── datasources/      # Источники данных
│   │   ├── demo_services_data.dart      # 15 сервисов
│   │   └── demo_gas_stations_data.dart  # 15 заправок
│   └── models/           # Модели данных
│
├── presentation/          # Слой представления
│   ├── screens/          # Экраны
│   │   ├── home/        # Главный экран с картой ⭐
│   │   ├── services/    # Список сервисов
│   │   ├── shop/        # Магазин
│   │   ├── profile/     # Профиль
│   │   └── auth/        # Авторизация
│   ├── widgets/         # Виджеты
│   └── providers/       # State management
│
└── main.dart             # Точка входа
```

---

## 🌍 Локализация

Приложение поддерживает:
- 🇷🇺 **Русский язык**
- 🇺🇿 **O'zbekcha (Узбекский)**

Файлы локализации: `assets/lang/`

---

## 🔧 Разработка

### Команды для разработки:

```bash
# Очистка проекта
flutter clean

# Установка зависимостей
flutter pub get

# Запуск в режиме разработки
flutter run

# Запуск в release режиме
flutter run --release

# Сборка APK
flutter build apk --release

# Сборка App Bundle
flutter build appbundle --release
```

### Требования:
- Flutter SDK ≥ 3.9.2
- Dart SDK ≥ 3.9.2
- Android SDK (для Android)
- Xcode (для iOS)

---

## 📝 История изменений

### Версия 1.0.0+1 (19 октября 2025)
- ✨ Добавлена интерактивная карта с Yandex MapKit
- ✨ Реализовано построение маршрутов на карте
- ✨ Добавлена интеграция с Google Maps
- ✨ 15 автосервисов с координатами
- ✨ 15 заправок с координатами
- ✨ Цветные маркеры для разных типов точек
- ✨ Поиск и фильтрация
- 🐛 Исправлены ошибки геолокации
- 📚 Создана подробная документация

Подробнее: [CHANGELOG_MAP.md](CHANGELOG_MAP.md)

---

## 🐛 Известные проблемы и решения

### Местоположение не определяется
**Решение:** Включите GPS и разрешите доступ к геолокации

### Маршрут не строится
**Решение:** Проверьте интернет-соединение

### Маркеры не видны
**Решение:** Увеличьте масштаб карты

Подробнее: [QUICK_TEST_GUIDE.md](QUICK_TEST_GUIDE.md) → "Если что-то не работает"

---

## 👥 Вклад в проект

Хотите помочь проекту? Отлично!

1. Fork репозиторий
2. Создайте ветку для вашей функции
3. Сделайте изменения
4. Отправьте Pull Request

---

## 📄 Лицензия

Этот проект является частным и предназначен для учебных целей.

---

## 📞 Контакты

Если у вас есть вопросы или предложения, свяжитесь с командой разработки.

---

## 🎉 Благодарности

Спасибо всем, кто участвовал в разработке этого проекта!

---

## 🚀 Готово к работе!

Приложение полностью функционально и готово к использованию.

**Начните с:** [FINAL_SUMMARY.md](FINAL_SUMMARY.md) ⭐

**Быстрое тестирование:** [QUICK_TEST_GUIDE.md](QUICK_TEST_GUIDE.md) ⚡

**Визуальное руководство:** [VISUAL_GUIDE.md](VISUAL_GUIDE.md) 🎨

---

_Последнее обновление: 19 октября 2025_  
_Версия: 1.0.0+1_  
_Статус: Production Ready ✅_




# 🚗 Auto Service - Flutter App with Maps

An application for finding auto repair shops and gas stations with an interactive map and navigation.

## ✨ Latest Update: Map with Navigation ⭐

**Date:** October 19, 2025
**Status:** ✅ Production Ready

### 🎯 New Features:

* 🗺️ **Interactive map** with 15 auto services and 15 gas stations
* 🛣️ **Route building** directly on Yandex Map
* 📱 **Google Maps integration** for navigation
* 🔍 **Search and filtering** by name and rating
* 📍 **Geolocation** with current position detection
* 🎨 **Colored markers**: red (services), green (stations), blue (you)

---

## 🚀 Quick Start

### Installation and launch:

```bash
# 1. Clone the project (if not yet done)
git clone <repository-url>
cd auto_service

# 2. Install dependencies
flutter clean
flutter pub get

# 3. Run the app
flutter run
```

### Or simply:

```bash
flutter clean && flutter pub get && flutter run
```

---

## 📚 Documentation

### 🌟 Start here:

| Document                                         | For whom                    | Reading time |
| ------------------------------------------------ | --------------------------- | ------------ |
| **[DOCS_INDEX.md](DOCS_INDEX.md)**               | Navigation through all docs | 2 min        |
| **[FINAL_SUMMARY.md](FINAL_SUMMARY.md)** ⭐       | Everyone - full overview    | 10 min       |
| **[QUICK_TEST_GUIDE.md](QUICK_TEST_GUIDE.md)** ⚡ | Quick testing               | 5 min        |
| **[VISUAL_GUIDE.md](VISUAL_GUIDE.md)** 🎨        | Visual instructions         | 5 min        |

### Full documentation:

* 📖 [MAP_UPDATE_GUIDE.md](MAP_UPDATE_GUIDE.md) - Detailed guide
* 🔧 [CHANGELOG_MAP.md](CHANGELOG_MAP.md) - Technical changes
* ✅ [UPDATE_COMPLETE.md](UPDATE_COMPLETE.md) - Work report
* 🎯 [MAP_UPDATE_README.md](MAP_UPDATE_README.md) - Summary overview

---

## 🎮 How to Use

### 1. First launch

```
Open the app → Allow geolocation → Done!
```

### 2. Viewing on the map

* Tap **🔧** on the right to see **red circles** (auto services)
* Tap **⛽** on the right to see **green circles** (gas stations)
* **Blue circle** - that’s you!

### 3. Building a route

```
Tap a circle → Info window opens →
Tap "Build route" → Blue line appears!
```

### 4. Navigation

* **On the map** - follow the blue line
* **In Google Maps** - tap "Open map"

---

## 🛠️ Technologies

### Core technologies:

* **Flutter SDK** ^3.9.2
* **Dart** ^3.9.2

### Key packages:

* **yandex_mapkit** ^4.2.1 - maps and routes
* **geolocator** ^13.0.1 - geolocation
* **url_launcher** ^6.2.5 - external links
* **easy_localization** ^3.0.8 - localization (RU/UZ)
* **provider** ^6.1.2 - state management

---

## 📱 App Features

### ✅ Implemented:

#### Map and Navigation:

* [x] Display of 15 auto services on the map
* [x] Display of 15 gas stations on the map
* [x] User location detection
* [x] Route building on Yandex Map
* [x] Google Maps integration
* [x] Toggle between services and stations
* [x] Color-coded markers by type

#### Interface:

* [x] Search by name
* [x] Filter by rating
* [x] Detailed point info
* [x] Dark and light themes
* [x] Bilingual (Russian/Uzbek)

#### Other sections:

* [x] Authentication & registration
* [x] Auto parts store
* [x] Shopping cart
* [x] Parts booking
* [x] Order history
* [x] User profile
* [x] App settings

---

## 🎨 Color Scheme

| Color        | Element    | Meaning       |
| ------------ | ---------- | ------------- |
| 🔴 Red       | Circle 30m | Auto service  |
| 🟢 Green     | Circle 30m | Gas station   |
| 🔵 Blue      | Circle 50m | Your location |
| 🔵 Blue line | Polyline   | Built route   |

---

## 📊 Project Structure

```
lib/
├── core/                   # App core
│   ├── constants/         # Constants, colors, strings
│   ├── theme/            # App themes
│   └── utils/            # Utilities
│
├── data/                  # Data layer
│   ├── datasources/      # Data sources
│   │   ├── demo_services_data.dart      # 15 services
│   │   └── demo_gas_stations_data.dart  # 15 stations
│   └── models/           # Data models
│
├── presentation/          # Presentation layer
│   ├── screens/          # Screens
│   │   ├── home/        # Main map screen ⭐
│   │   ├── services/    # Services list
│   │   ├── shop/        # Store
│   │   ├── profile/     # Profile
│   │   └── auth/        # Auth
│   ├── widgets/         # Widgets
│   └── providers/       # State management
│
└── main.dart             # Entry point
```

---

## 🌍 Localization

Supported languages:

* 🇷🇺 **Russian**
* 🇺🇿 **O'zbekcha (Uzbek)**

Localization files: `assets/lang/`

---

## 🔧 Development

### Development commands:

```bash
# Clean project
flutter clean

# Install dependencies
flutter pub get

# Run in dev mode
flutter run

# Run in release mode
flutter run --release

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### Requirements:

* Flutter SDK ≥ 3.9.2
* Dart SDK ≥ 3.9.2
* Android SDK (for Android)
* Xcode (for iOS)

---

## 📝 Changelog

### Version 1.0.0+1 (October 19, 2025)

* ✨ Added interactive map with Yandex MapKit
* ✨ Implemented route building
* ✨ Added Google Maps integration
* ✨ 15 auto services with coordinates
* ✨ 15 gas stations with coordinates
* ✨ Color-coded markers by type
* ✨ Search and filtering
* 🐛 Fixed geolocation bugs
* 📚 Created detailed documentation

More details: [CHANGELOG_MAP.md](CHANGELOG_MAP.md)

---

## 🐛 Known Issues and Fixes

### Location not detected

**Fix:** Enable GPS and allow location access

### Route not building

**Fix:** Check internet connection

### Markers not visible

**Fix:** Zoom in on the map

More: [QUICK_TEST_GUIDE.md](QUICK_TEST_GUIDE.md) → "If something doesn’t work"

---

## 👥 Contributing

Want to help improve the project? Great!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a Pull Request

---

## 📄 License

This project is private and intended for educational use only.

---

## 📞 Contacts

For any questions or suggestions, contact the development team.

---

## 🎉 Credits

Thanks to everyone who participated in this project!

---

## 🚀 Ready to Go!

The app is fully functional and production-ready.

**Start with:** [FINAL_SUMMARY.md](FINAL_SUMMARY.md) ⭐

**Quick testing:** [QUICK_TEST_GUIDE.md](QUICK_TEST_GUIDE.md) ⚡

**Visual guide:** [VISUAL_GUIDE.md](VISUAL_GUIDE.md) 🎨

---

*Last update: October 19, 2025*
*Version: 1.0.0+1*
*Status: Production Ready ✅*
