# Инструкция по запуску проекта Auto Service на MacBook M1 Max

## Проблемы, которые были исправлены:
1. ✅ Обновлен минимальный iOS deployment target до 14.0 (для лучшей совместимости с M1)
2. ✅ Настроен Podfile для поддержки архитектуры arm64 на симуляторе M1
3. ✅ Добавлены необходимые разрешения для геолокации в Info.plist
4. ✅ Создан скрипт автоматической настройки проекта

## Быстрый запуск:

### 1. Сделайте скрипт исполняемым и запустите его:
```bash
cd /Users/marcus/Documents/auto_service_app
chmod +x setup_ios.sh
./setup_ios.sh
```

Скрипт автоматически:
- Очистит старые зависимости
- Установит Flutter зависимости
- Настроит CocoaPods для iOS

### 2. Запустите приложение:

**Вариант A: Через командную строку**
```bash
# Откройте симулятор iOS
open -a Simulator

# Запустите приложение
flutter run
```

**Вариант B: Через Xcode**
```bash
# Откройте workspace в Xcode
open ios/Runner.xcworkspace
```
Затем нажмите кнопку Run (▶️) в Xcode

## Если возникают проблемы:

### Проблема 1: Ошибки с CocoaPods
```bash
cd ios
pod deintegrate
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### Проблема 2: Ошибки компиляции
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

### Проблема 3: Ошибка "No simulator found"
1. Откройте Xcode
2. Перейдите в Window → Devices and Simulators
3. Создайте новый симулятор iPhone (рекомендуется iPhone 14 или новее)

### Проблема 4: Ошибки с YandexMapKit
Убедитесь, что в Info.plist есть YMKApiKey. Он уже добавлен в проект:
```xml
<key>YMKApiKey</key>
<string>20a40c6c-d27c-46b6-b96a-b4b6a4cb47ba</string>
```

## Требования к системе:
- macOS 12.0 или новее
- Xcode 14.0 или новее
- Flutter 3.0 или новее
- CocoaPods 1.11.0 или новее

## Полезные команды:

### Проверка доступных симуляторов:
```bash
xcrun simctl list devices available
```

### Запуск на конкретном симуляторе:
```bash
flutter run -d "iPhone 14 Pro"
```

### Просмотр логов:
```bash
flutter logs
```

## Особенности проекта:
- Приложение использует Yandex MapKit для отображения карт
- Требуется доступ к геолокации
- Поддерживает выбор фотографий из галереи и камеры
- Использует локальное хранилище данных

## Контакты для помощи:
Если у вас остались вопросы, проверьте:
1. Версию Flutter: `flutter --version`
2. Версию Xcode: `xcodebuild -version`
3. Статус Flutter Doctor: `flutter doctor -v`
