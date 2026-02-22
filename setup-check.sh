#!/bin/bash

# Цвета для процесса установки
G='\e[0;32m'
B='\e[0;36m'
Y='\e[1;33m'
NC='\e[0m'

echo -e "${B}Запуск установки системного диагноста...${NC}"

# 1. Ссылка на основной скрипт 
SCRIPT_URL="https://raw.githubusercontent.com/ms-bubu/check-server/refs/heads/main/check-server.sh"
DEST="/root/check-server.sh"

# 2. Скачивание
echo -e "${Y}Скачиваю скрипт в $DEST...${NC}"
curl -sSL "$SCRIPT_URL" -o "$DEST"

# 3. Права на выполнение
chmod +x "$DEST"

# 4. Создание алиаса "check" для удобства
# Проверяем, нет ли уже такого алиаса в .bashrc
if ! grep -q "alias check=" ~/.bashrc; then
    echo "alias check='sudo /root/check-server.sh'" >> ~/.bashrc
    echo -e "${G}Алиас 'check' добавлен в .bashrc${NC}"
fi

echo -e "${G}Установка завершена!${NC}"
echo -e "Теперь вы можете запускать диагностику командой: ${Y}check${NC}"
echo -e "${B}------------------------------------------------${NC}"

# 5. Сразу запускаем для проверки
source ~/.bashrc 2>/dev/null
bash "$DEST"
