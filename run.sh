#!/bin/bash

echo "🚀 Запуск Auto Service App..."
echo ""

# Проверяем, запущен ли симулятор
if pgrep -x "Simulator" > /dev/null; then
    echo "✅ Симулятор уже запущен"
else
    echo "📱 Запускаем симулятор..."
    open -a Simulator
    # Ждем пока симулятор загрузится
    sleep 5
fi

# Проверяем доступные устройства
echo ""
echo "🔍 Доступные устройства:"
flutter devices

echo ""
echo "▶️  Запускаем приложение..."
flutter run
