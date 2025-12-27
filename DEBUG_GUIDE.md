# Полезные команды для отладки Auto Service App

## Диагностика Flutter
```bash
# Проверка установки Flutter и зависимостей
flutter doctor -v

# Проверка доступных устройств
flutter devices

# Очистка кэша Flutter
flutter clean
```

## Работа с iOS симулятором
```bash
# Список всех симуляторов
xcrun simctl list devices

# Запуск конкретного симулятора
open -a Simulator --args -CurrentDeviceUDID <DEVICE_ID>

# Удаление всех недоступных симуляторов
xcrun simctl delete unavailable
```

## CocoaPods команды
```bash
# Обновление CocoaPods
sudo gem install cocoapods

# Обновление репозиториев
pod repo update

# Полная переустановка зависимостей
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

## Решение типичных проблем

### 1. Ошибка "Building for iOS Simulator, but the linked framework was built for iOS"
Эта проблема уже решена в обновленном Podfile. Если всё равно возникает:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### 2. Ошибка с архитектурой arm64
Проверьте в Xcode:
1. Открыть `ios/Runner.xcworkspace`
2. Выбрать Runner в левой панели
3. Build Settings → Architectures
4. Убедитесь что "Build Active Architecture Only" = YES для Debug

### 3. Проблемы с разрешениями (Location, Camera, Photos)
Все разрешения уже добавлены в Info.plist:
- NSLocationWhenInUseUsageDescription
- NSLocationAlwaysUsageDescription
- NSCameraUsageDescription
- NSPhotoLibraryUsageDescription

### 4. Ошибки YandexMapKit
YandexMapKit требует iOS 14.0+. Проверьте:
```bash
# В ios/Podfile должно быть:
platform :ios, '14.0'
```

## Логи и отладка
```bash
# Запуск с подробными логами
flutter run -v

# Просмотр логов в реальном времени
flutter logs

# Логи конкретного устройства
flutter logs -d <device_id>
```

## Сборка релизной версии
```bash
# Сборка IPA файла
flutter build ipa

# Сборка без код-сигнинга (для тестирования)
flutter build ios --no-codesign
```

## Очистка и пересборка
```bash
# Полная очистка проекта
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf build
rm -rf .dart_tool

# Пересборка
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Проверка производительности
```bash
# Запуск в profile режиме
flutter run --profile

# Запуск в release режиме
flutter run --release
```

## Управление зависимостями
```bash
# Проверка устаревших пакетов
flutter pub outdated

# Обновление зависимостей
flutter pub upgrade

# Получение конкретной версии
flutter pub get
```

## Xcode команды
```bash
# Открыть workspace
open ios/Runner.xcworkspace

# Очистка Derived Data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Проверка версии Xcode
xcodebuild -version
```

## Hot Reload и Hot Restart
Во время работы приложения:
- `r` - Hot reload (быстрая перезагрузка)
- `R` - Hot restart (полная перезагрузка)
- `h` - Помощь
- `q` - Выход

## Если ничего не помогает
```bash
# Полная переустановка с нуля
cd /Users/marcus/Documents/auto_service_app
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf build .dart_tool
flutter clean
flutter pub get
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter run
```

## Проверка перед запуском
```bash
# Убедитесь что всё настроено правильно
flutter doctor
flutter devices
cd ios && pod --version && cd ..
xcodebuild -version
```
