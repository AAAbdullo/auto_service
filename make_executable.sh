#!/bin/bash

echo "🔧 Делаем все скрипты исполняемыми..."

chmod +x setup_ios.sh
chmod +x run.sh
chmod +x menu.sh
chmod +x welcome.sh
chmod +x make_executable.sh

echo "✅ Все скрипты теперь исполняемые!"
echo ""
echo "Доступные команды:"
echo "  ./welcome.sh    - Приветственное сообщение"
echo "  ./setup_ios.sh  - Первая настройка проекта"
echo "  ./run.sh        - Быстрый запуск приложения"
echo "  ./menu.sh       - Интерактивное меню"
echo ""
echo "🎉 Рекомендуем начать с: ./welcome.sh"
