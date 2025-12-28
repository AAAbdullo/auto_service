#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Auto Service App - Быстрые команды   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

PS3='Выберите действие: '
options=(
    "🚀 Запустить приложение"
    "🔧 Настроить проект с нуля"
    "🧹 Очистить и пересобрать"
    "📱 Открыть симулятор"
    "🔍 Проверить Flutter Doctor"
    "📦 Обновить зависимости"
    "🍎 Переустановить CocoaPods"
    "📊 Посмотреть логи"
    "🏗️  Собрать Release версию"
    "❌ Выход"
)

select opt in "${options[@]}"
do
    case $opt in
        "🚀 Запустить приложение")
            echo -e "${GREEN}Запускаем приложение...${NC}"
            open -a Simulator
            sleep 3
            flutter run
            break
            ;;
        "🔧 Настроить проект с нуля")
            echo -e "${GREEN}Настраиваем проект...${NC}"
            chmod +x setup_ios.sh
            ./setup_ios.sh
            break
            ;;
        "🧹 Очистить и пересобрать")
            echo -e "${GREEN}Очищаем проект...${NC}"
            flutter clean
            rm -rf ios/Pods ios/Podfile.lock
            rm -rf build .dart_tool
            flutter pub get
            cd ios && pod install && cd ..
            echo -e "${GREEN}✅ Готово!${NC}"
            break
            ;;
        "📱 Открыть симулятор")
            echo -e "${GREEN}Открываем симулятор...${NC}"
            open -a Simulator
            break
            ;;
        "🔍 Проверить Flutter Doctor")
            echo -e "${GREEN}Проверяем Flutter...${NC}"
            flutter doctor -v
            break
            ;;
        "📦 Обновить зависимости")
            echo -e "${GREEN}Обновляем зависимости...${NC}"
            flutter pub get
            cd ios && pod install && cd ..
            echo -e "${GREEN}✅ Зависимости обновлены!${NC}"
            break
            ;;
        "🍎 Переустановить CocoaPods")
            echo -e "${GREEN}Переустанавливаем CocoaPods...${NC}"
            cd ios
            pod deintegrate
            rm -rf Pods Podfile.lock
            pod install --repo-update
            cd ..
            echo -e "${GREEN}✅ CocoaPods переустановлен!${NC}"
            break
            ;;
        "📊 Посмотреть логи")
            echo -e "${GREEN}Показываем логи...${NC}"
            flutter logs
            break
            ;;
        "🏗️  Собрать Release версию")
            echo -e "${GREEN}Собираем Release версию...${NC}"
            flutter build ios --release
            echo -e "${GREEN}✅ Сборка завершена!${NC}"
            break
            ;;
        "❌ Выход")
            echo -e "${BLUE}До свидания!${NC}"
            break
            ;;
        *) 
            echo -e "${RED}Неверный выбор${NC}"
            ;;
    esac
done
