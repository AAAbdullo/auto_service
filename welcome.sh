#!/bin/bash

# Цвета
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

clear

# Отображаем welcome сообщение
cat WELCOME.txt

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Хотите запустить приложение прямо сейчас? (y/n)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY]|[дД][аА]|[дД])$ ]]; then
    echo ""
    echo -e "${BLUE}Отлично! Запускаем интерактивное меню...${NC}"
    sleep 1
    chmod +x menu.sh
    ./menu.sh
else
    echo ""
    echo -e "${GREEN}Хорошо! Когда будете готовы, запустите:${NC}"
    echo -e "${BLUE}./menu.sh${NC}"
    echo ""
fi
