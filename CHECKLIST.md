# ✅ Чек-лист проверки перед запуском

Используйте этот чек-лист, чтобы убедиться, что всё настроено правильно.

## 📋 Предварительные проверки

### 1. Flutter установлен и работает
```bash
flutter --version
```
- [ ] Flutter версия 3.0.0 или выше
- [ ] Dart версия совместима

### 2. Xcode установлен и настроен
```bash
xcodebuild -version
```
- [ ] Xcode версия 14.0 или выше
- [ ] Command Line Tools установлены

### 3. CocoaPods установлен
```bash
pod --version
```
- [ ] CocoaPods версия 1.11.0 или выше

### 4. Flutter Doctor проходит
```bash
flutter doctor -v
```
- [ ] ✅ Flutter (проверка успешна)
- [ ] ✅ Xcode (проверка успешна)
- [ ] ✅ iOS toolchain (проверка успешна)
- [ ] ✅ Все необходимые компоненты установлены

## 🔍 Проверка конфигурации проекта

### 5. Podfile настроен для M1
```bash
cat ios/Podfile | grep "platform :ios"
```
- [ ] Должно быть: `platform :ios, '14.0'`

### 6. Info.plist содержит необходимые разрешения
```bash
cat ios/Runner/Info.plist | grep "NSLocation"
```
- [ ] NSLocationWhenInUseUsageDescription присутствует
- [ ] NSLocationAlwaysUsageDescription присутствует
- [ ] YMKApiKey присутствует

### 7. Dependencies установлены
```bash
ls -la ios/Pods
```
- [ ] Папка Pods существует
- [ ] Pods содержит зависимости (YandexMapsMobile и др.)

## 🚀 Готовность к запуску

### 8. Симулятор доступен
```bash
xcrun simctl list devices | grep "iPhone"
```
- [ ] Хотя бы один iPhone симулятор доступен

### 9. Проект собирается
```bash
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -sdk iphonesimulator -configuration Debug ONLY_ACTIVE_ARCH=YES | grep "BUILD SUCCEEDED"
cd ..
```
- [ ] BUILD SUCCEEDED

### 10. Скрипты исполняемые
```bash
ls -la *.sh
```
- [ ] setup_ios.sh имеет права на выполнение
- [ ] run.sh имеет права на выполнение
- [ ] menu.sh имеет права на выполнение

## 🎯 Финальная проверка

### Если все пункты выше выполнены:
```bash
./menu.sh
```
Выберите "🚀 Запустить приложение"

### Или просто:
```bash
flutter run
```

## ❌ Если что-то не работает

### Проблема: Flutter doctor показывает ошибки
**Решение:**
```bash
flutter doctor --android-licenses  # Для Android
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer  # Для iOS
```

### Проблема: CocoaPods не установлен
**Решение:**
```bash
sudo gem install cocoapods
```

### Проблема: Pods не установлены
**Решение:**
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
```

### Проблема: Симулятор не работает
**Решение:**
```bash
# Откройте Xcode → Preferences → Locations
# Убедитесь что Command Line Tools выбран
open -a Xcode
```

### Проблема: Сборка не проходит
**Решение:**
```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## 📞 Дополнительная помощь

Если проблемы остались:
1. Проверьте [DEBUG_GUIDE.md](DEBUG_GUIDE.md)
2. Запустите полную переустановку: `./setup_ios.sh`
3. Проверьте версии всех инструментов

## ✨ Успех!

Если все проверки пройдены ✅, ваш проект готов к запуску! 🎉

```bash
flutter run
```
