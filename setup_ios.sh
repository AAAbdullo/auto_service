#!/bin/bash

echo "🧹 Очистка проекта..."

# Удаляем старые зависимости
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf build
rm -rf .dart_tool

echo "📦 Получаем зависимости Flutter..."
flutter clean
flutter pub get

echo "🍎 Устанавливаем CocoaPods зависимости..."
cd ios
pod deintegrate
pod install --repo-update
cd ..

echo "✅ Проект готов к запуску!"
echo ""
echo "Теперь вы можете запустить приложение:"
echo "1. Откройте симулятор iOS"
echo "2. Выполните команду: flutter run"
echo ""
echo "Или откройте проект в Xcode:"
echo "open ios/Runner.xcworkspace"
