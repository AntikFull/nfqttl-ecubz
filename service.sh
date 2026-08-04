#!/system/bin/sh
MODDIR=${0%/*}

# ============================================================================
# Nfqttl eCubz v5.3 - Smart Multi-Engine Mobile Tethering & Custom Blocklist
# ============================================================================

PGREP_BIN=/system/bin/pgrep

nfqttl_alive() {
    if [ -x "$PGREP_BIN" ]; then
        "$PGREP_BIN" -x nfqttl >/dev/null 2>&1
        return $?
    fi
    for _p in /proc/[0-9]*; do
        [ -r "$_p/comm" ] || continue
        read -r _c < "$_p/comm" 2>/dev/null || continue
        [ "$_c" = "nfqttl" ] && return 0
    done
    return 1
}

# Сброс старых процессов демона при перезапуске
pkill -9 nfqttl 2>/dev/null || true
sleep 1

# Очистка старых правил
iptables -t mangle -D PREROUTING -j nfqttli 2>/dev/null || true
iptables -t mangle -D OUTPUT -j nfqttlo 2>/dev/null || true
iptables -t mangle -D POSTROUTING -o rmnet+ -j nfqttlo 2>/dev/null || true
iptables -t mangle -D POSTROUTING -o rmnet_data+ -j nfqttlo 2>/dev/null || true
iptables -t mangle -D POSTROUTING -o wlan+ -j nfqttlo 2>/dev/null || true
iptables -t mangle -D POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtud 2>/dev/null || true

iptables -t mangle -D FORWARD -i wlan+ -p udp --dport 123 -j DROP 2>/dev/null || true

ip6tables -t mangle -D PREROUTING -j nfqttli 2>/dev/null || true
ip6tables -t mangle -D POSTROUTING -j nfqttlo 2>/dev/null || true
ip6tables -t mangle -D POSTROUTING -o rmnet+ -j nfqttlo 2>/dev/null || true
ip6tables -t mangle -D POSTROUTING -o rmnet_data+ -j nfqttlo 2>/dev/null || true
ip6tables -t mangle -D POSTROUTING -o wlan+ -j nfqttlo 2>/dev/null || true
ip6tables -t mangle -D FORWARD -i wlan+ -j DROP 2>/dev/null || true

# 1. Защита от NTP
iptables -t mangle -A FORWARD -i wlan+ -p udp --dport 123 -j DROP 2>/dev/null || true

# 2. Динамический парсинг и подгрузка блокировок из blocklist.txt
BLOCKLIST_FILE="$MODDIR/blocklist.txt"
if [ -f "$BLOCKLIST_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        domain=$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr -d '\r')
        [ -z "$domain" ] && continue

        iptables -t mangle -D FORWARD -i wlan+ -m string --string "$domain" --algo bm -j DROP 2>/dev/null || true
        iptables -t mangle -A FORWARD -i wlan+ -m string --string "$domain" --algo bm -j DROP 2>/dev/null || true
    done < "$BLOCKLIST_FILE"
fi

# 3. Коррекция TCP MSS (защита от детекции размера TCP окна ПК)
iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtud 2>/dev/null || true

# 4. Безопасная обработка IPv6 (Защита от утечки IPv6 TTL на раздаче)
if grep -q HL /proc/net/ip6_tables_targets 2>/dev/null; then
    ip6tables -t mangle -A POSTROUTING -o rmnet+ -j HL --hl-set 64 2>/dev/null || true
    ip6tables -t mangle -A POSTROUTING -o rmnet_data+ -j HL --hl-set 64 2>/dev/null || true
else
    ip6tables -t mangle -A FORWARD -i wlan+ -j DROP 2>/dev/null || true
fi

# 5. Авто-выбор движка подмены IPv4 TTL: Kernel TTL vs Userspace NFQUEUE
if grep -q TTL /proc/net/ip_tables_targets 2>/dev/null; then
    # ------------------------------------------------------------------------
    # РЕЖИМ 1: Нативный Kernel TTL (0% нагрузки на CPU)
    # ------------------------------------------------------------------------
    iptables -t mangle -D POSTROUTING -o rmnet+ -j TTL --ttl-set 64 2>/dev/null || true
    iptables -t mangle -D POSTROUTING -o rmnet_data+ -j TTL --ttl-set 64 2>/dev/null || true
    iptables -t mangle -D PREROUTING -i wlan+ -j TTL --ttl-set 64 2>/dev/null || true

    iptables -t mangle -A POSTROUTING -o rmnet+ -j TTL --ttl-set 64 2>/dev/null || true
    iptables -t mangle -A POSTROUTING -o rmnet_data+ -j TTL --ttl-set 64 2>/dev/null || true
    iptables -t mangle -A PREROUTING -i wlan+ -j TTL --ttl-set 64 2>/dev/null || true
else
    # ------------------------------------------------------------------------
    # РЕЖИМ 2: Userspace NFQUEUE + Daemon Nfqttl (с Watchdog и --queue-bypass)
    # ------------------------------------------------------------------------
    if ! nfqttl_alive; then
        "$MODDIR/nfqttl" -d -s -u
        sleep 2
    fi

    iptables -t mangle -N nfqttlo 2>/dev/null || true
    iptables -t mangle -F nfqttlo
    iptables -t mangle -A nfqttlo -j NFQUEUE --queue-num 6464 --queue-bypass

    iptables -t mangle -A POSTROUTING -o rmnet+ -j nfqttlo 2>/dev/null || true
    iptables -t mangle -A POSTROUTING -o rmnet_data+ -j nfqttlo 2>/dev/null || true
    iptables -t mangle -A POSTROUTING -o wlan+ -j nfqttlo 2>/dev/null || true

    ip6tables -t mangle -N nfqttlo 2>/dev/null || true
    ip6tables -t mangle -F nfqttlo
    ip6tables -t mangle -A nfqttlo -j NFQUEUE --queue-num 6464 --queue-bypass

    ip6tables -t mangle -A POSTROUTING -o rmnet+ -j nfqttlo 2>/dev/null || true
    ip6tables -t mangle -A POSTROUTING -o rmnet_data+ -j nfqttlo 2>/dev/null || true
    ip6tables -t mangle -A POSTROUTING -o wlan+ -j nfqttlo 2>/dev/null || true

    # Watchdog для защиты работы NFQUEUE демона
    WD_LOG=/data/local/tmp/nfqttl_watchdog.log
    WD_INTERVAL=60
    WD_MAX_RESTARTS=20

    wd_log() {
        if [ -f "$WD_LOG" ] && [ "$(wc -c < "$WD_LOG" 2>/dev/null || echo 0)" -gt 65536 ]; then
            tail -n 50 "$WD_LOG" > "$WD_LOG.tmp" 2>/dev/null && mv "$WD_LOG.tmp" "$WD_LOG"
        fi
        echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$WD_LOG"
    }

    watchdog() {
        restarts=0
        wd_log "watchdog запущен (интервал ${WD_INTERVAL}с, лимит ${WD_MAX_RESTARTS} перезапусков)"
        while true; do
            sleep "$WD_INTERVAL"

            nfqttl_alive && continue

            if [ "$restarts" -ge "$WD_MAX_RESTARTS" ]; then
                wd_log "демон мёртв, лимит перезапусков исчерпан — прекращаю попытки"
                break
            fi

            restarts=$((restarts + 1))
            wd_log "демон не найден, перезапуск #$restarts"
            "$MODDIR/nfqttl" -d -s -u
            sleep 3
        done
    }

    watchdog &
fi

exit 0
