# 🎯 Шпаргалка - Auto Service App

## ⚡ БЫСТРЫЕ КОМАНДЫ

```bash
# Самый простой способ запуска
./menu.sh

# Или быстрый запуск
./run.sh

# Или вручную
open -a Simulator && flutter run
```

## 📁 ВАЖНЫЕ ФАЙЛЫ

| Файл | Описание |
|------|----------|
| `START_HERE.md` | **НАЧНИТЕ ОТСЮДА** |
| `CHECKLIST.md` | Проверка перед запуском |
| `SETUP_INSTRUCTIONS.md` | Детальная установка |
| `DEBUG_GUIDE.md` | Решение проблем |

## 🛠️ ОСНОВНЫЕ КОМАНДЫ

```bash
# Запуск
flutter run

# Горячая перезагрузка (в терминале с запущенным приложением)
r      # Быстрая перезагрузка
R      # Полная перезагрузка
q      # Выход

# Очистка
flutter clean

# Переустановка зависимостей
flutter pub get
cd ios && pod install && cd ..

# Проверка
flutter doctor -v
flutter devices

# Логи
flutter logs
```

## 🚨 БЫСТРОЕ РЕШЕНИЕ ПРОБЛЕМ

### Проблема: Не запускается
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Проблема: Ошибки сборки iOS
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter run
```

### Проблема: Симулятор не найден
```bash
open -a Simulator
# Подождите загрузки, затем:
flutter run
```

### Проблема: Всё сломалось
```bash
./setup_ios.sh  # Полная переустановка
```

## 📱 СИМУЛЯТОРЫ

```bash
# Список симуляторов
xcrun simctl list devices

# Запуск симулятора
open -a Simulator

# Запуск на конкретном симуляторе
flutter run -d "iPhone 14 Pro"
```

## 🔍 ДИАГНОСТИКА

```bash
# Полная диагностика
flutter doctor -v

# Проверка Xcode
xcodebuild -version

# Проверка CocoaPods
pod --version

# Проверка Flutter
flutter --version
```

## 📦 ЗАВИСИМОСТИ

```bash
# Получить зависимости Flutter
flutter pub get

# Установить CocoaPods
cd ios && pod install && cd ..

# Обновить всё
flutter pub upgrade
cd ios && pod update && cd ..
```

## 🎨 СБОРКА

```bash
# Debug сборка
flutter build ios --debug

# Release сборка
flutter build ios --release

# Profile сборка
flutter run --profile
```

## 🗂️ СТРУКТУРА ПРОЕКТА

```
/auto_service_app
├── lib/               # Исходный код Dart
│   ├── core/         # Базовая логика
│   ├── data/         # Модели данных
│   └── presentation/ # UI
├── ios/              # iOS конфигурация
│   ├── Podfile       # CocoaPods зависимости
│   └── Runner/       # iOS проект
├── assets/           # Ресурсы (иконки, изображения)
└── *.sh              # Скрипты запуска
```

## 💡 ПОЛЕЗНЫЕ ССЫЛКИ

- **Flutter Docs**: https://docs.flutter.dev
- **Yandex MapKit**: https://yandex.ru/dev/mapkit/
- **Flutter iOS Setup**: https://docs.flutter.dev/get-started/install/macos

## 🆘 ПОМОЩЬ

1. Проверьте `CHECKLIST.md`
2. Изучите `DEBUG_GUIDE.md`
3. Запустите `flutter doctor -v`
4. Переустановите: `./setup_ios.sh`

## ✨ ФИЧИ ПРОЕКТА

- 🗺️ Yandex Карты
- 📍 Геолокация
- 🛒 Корзина покупок
- 📅 Бронирование
- 🌐 Русский/Узбекский
- 📱 Адаптивный UI

---

**Быстрый старт:** `./menu.sh` → "🚀 Запустить приложение"
