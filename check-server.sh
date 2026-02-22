
#!/bin/bash

# Цвета
G='\e[0;32m'
R='\e[0;31m'
Y='\e[1;33m'
B='\e[0;36m'
NC='\e[0m'

echo -e "${B}========== ПОЛНЫЙ АУДИТ СЕРВЕРА (v4.0) ==========${NC}"

# 1. СЕТЕВОЙ ТРАФИК
echo -e "\n${Y}📡 СЕТЕВАЯ АКТИВНОСТЬ:${NC}"
cat /proc/net/dev | grep -E "eth|enp|eno|ers|venet|vda" | awk '{printf "  - %-7s: Принято: %-8.2f MB | Отправлено: %.2f MB\n", $1, $2/1024/1024, $10/1024/1024}'

# 2. АНАЛИЗ АТАК (TOP-20 + Чистое время)
echo -e "\n${R}🛡️  ТОП-20 ПОПЫТОК ВЗЛОМА SSH:${NC}"
AUTH_LOG="/var/log/auth.log"
if [ -f "$AUTH_LOG" ]; then
    printf "  %-5s | %-15s | %-5s | %-12s\n" "Поп." "IP адрес" "Стр." "Последний вход"
    echo "  ----------------------------------------------------------"
    
    # Собираем топ 20 IP
    ATTACKS=$(grep "Failed password" "$AUTH_LOG" | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | head -n 20)
    
    if [ ! -z "$ATTACKS" ]; then
        echo "$ATTACKS" | while read count ip; do
            # Узнаем страну (коротко)
            COUNTRY=$(curl -s --connect-timeout 2 ipinfo.io/$ip/country || echo "??")
            
            # Находим время последней попытки и чистим его
            # Формат: Feb 22 07:33
            LAST_TIME=$(grep "$ip" "$AUTH_LOG" | tail -n 1 | awk '{print $1,$2,$3}')
            # Если лог в формате ISO (как у тебя), переформатируем:
            if [[ $LAST_TIME == *"T"* ]]; then
                 LAST_TIME=$(echo $LAST_TIME | cut -dT -f1,2 | sed 's/T/ /' | cut -c 6-16)
            fi
            
            printf "  %-5s | %-15s | %-16b | %-12b\n" "$count" "$ip" "${G}$COUNTRY${NC}" "${Y}$LAST_TIME${NC}"
        done
    else
        echo "  Попыток взлома не обнаружено."
    fi
fi

# 3. КТО СЛУШАЕТ ПОРТЫ
echo -e "\n${B}🔌 КТО СЛУШАЕТ ПОРТЫ:${NC}"
ss -tulpn | grep LISTEN | awk '{print $5, $7}' | sed 's/users:(("//' | sed 's/",.*//' | awk -F: '{split($NF, a, " "); printf "  - %-5s | %s\n", a[1], $2}' | sort -u

# 4. ТОП-10 ПРОЦЕССОВ
echo -e "\n${G}🔥 ТОП-10 ПРОЦЕССОВ ПО CPU:${NC}"
ps -eo comm,%cpu,%mem --sort=-%cpu | head -n 11 | tail -n 10 | awk '{printf "  - %-15s | CPU: %-5s | RAM: %s%%\n", $1, $2, $3}'

# 5. ДИСКИ
echo -e "\n${Y}💾 СОСТОЯНИЕ ДИСКОВ:${NC}"
df -h -x tmpfs -x devtmpfs | grep '^/' | awk '{printf "  - %-15s: %s / %s (%s)\n", $1, $3, $2, $5}'

# 6. КРИТИЧЕСКИЕ СОБЫТИЯ
echo -e "\n${R}🚨 ПОСЛЕДНИЕ КРИТИЧЕСКИЕ СОБЫТИЯ:${NC}"
journalctl -p err..emerg -n 5 --no-hostname --no-pager | sed 's/^/  /'

echo -e "\n${B}========================================================${NC}"
