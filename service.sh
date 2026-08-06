#!/system/bin/sh
MODDIR=${0%/*}

# ============================================================================
# Nfqttl eCubz v7.7 - Clean Cellular Ingress & Ultimate Tethering Reliability
# Compatible with: OnePlus 13 (Android 15/16), OxygenOS, Xiaomi, Samsung, All
# ============================================================================

VERSION="v7.7"
VERSION_CODE="27"

# Фиксация примененной версии для предотвращения путаницы логов без перезагрузки
echo "$VERSION ($VERSION_CODE)" > "$MODDIR/.applied_version" 2>/dev/null || true

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

# 1. Отключение всех видов Tethering Offload (Hardware HAL + Android 12-15 eBPF Offload)
device_config put connectivity override_tether_enable_bpf_offload false 2>/dev/null || true
settings put global tether_offload_disabled 1 2>/dev/null || true
setprop persist.sys.tether.offload.enable false 2>/dev/null || true

# 2. Принудительное включение форвардинга IPv4 и IPv6
echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true
sysctl -w net.ipv4.ip_forward=1 2>/dev/null || true
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null || true
sysctl -w net.ipv6.conf.all.forwarding=1 2>/dev/null || true
sysctl -w net.ipv6.conf.all.disable_ipv6=0 2>/dev/null || true

# Сброс старых процессов демона при перезапуске
pkill -9 nfqttl 2>/dev/null || true
sleep 1

DEBUG_MODE=0
if [ -f "$MODDIR/debug" ] || [ -f "$MODDIR/DEBUG" ]; then
    DEBUG_MODE=1
fi

# 3. Полная и симметричная очистка старых правил MANGLE, NAT и унаследованных правил
iptables -t mangle -F nfqttlo 2>/dev/null || true
iptables -t mangle -D OUTPUT -j nfqttlo 2>/dev/null || true
iptables -t mangle -D POSTROUTING ! -o lo -j nfqttlo 2>/dev/null || true

ip6tables -t mangle -F nfqttlo 2>/dev/null || true
ip6tables -t mangle -D POSTROUTING -j nfqttlo 2>/dev/null || true

for _celnt in rmnet+ rmnet_data+ r_rmnet_data+ rmnet_mhi+ rmnet_ipa+ ccmni+ pdp+; do
    iptables -t mangle -D POSTROUTING -o "$_celnt" -j nfqttlo 2>/dev/null || true
    iptables -t mangle -D POSTROUTING -o "$_celnt" -j TTL --ttl-set 64 2>/dev/null || true
    iptables -t mangle -D POSTROUTING -o "$_celnt" -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtud 2>/dev/null || true
    iptables -t mangle -D PREROUTING -i "$_celnt" -m ttl --ttl-eq 1 -j DROP 2>/dev/null || true

    ip6tables -t mangle -D POSTROUTING -o "$_celnt" -j nfqttlo 2>/dev/null || true
    ip6tables -t mangle -D POSTROUTING -o "$_celnt" -j HL --hl-set 64 2>/dev/null || true
done

for _if in wlan+ ap+ swlan+ softap+ rndis+ usb+ bt-pan+ pan+; do
    iptables -t mangle -D POSTROUTING -o "$_if" -j nfqttlo 2>/dev/null || true
    iptables -t mangle -D POSTROUTING -o "$_if" -j TTL --ttl-set 64 2>/dev/null || true
    iptables -t mangle -D POSTROUTING -o "$_if" -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtud 2>/dev/null || true

    iptables -t mangle -D FORWARD -o "$_if" -j nfqttlo 2>/dev/null || true
    iptables -t mangle -D FORWARD -i "$_if" -j nfqttlo 2>/dev/null || true

    ip6tables -t mangle -D POSTROUTING -o "$_if" -j nfqttlo 2>/dev/null || true
    ip6tables -t mangle -D POSTROUTING -o "$_if" -j HL --hl-set 64 2>/dev/null || true

    iptables -t mangle -D FORWARD -i "$_if" -p udp --dport 123 -j DROP 2>/dev/null || true
    iptables -t mangle -D FORWARD -i "$_if" -p tcp --dport 853 -j DROP 2>/dev/null || true
    iptables -t mangle -D FORWARD -i "$_if" -p udp --dport 123 -j LOG --log-prefix "NFQTTL-NTP-BLOCK: " 2>/dev/null || true
    iptables -t nat -D PREROUTING -i "$_if" -p udp --dport 53 -j REDIRECT --to-ports 53 2>/dev/null || true
    iptables -t nat -D PREROUTING -i "$_if" -p tcp --dport 53 -j REDIRECT --to-ports 53 2>/dev/null || true

    ip6tables -t mangle -D FORWARD -i "$_if" -p udp --dport 123 -j DROP 2>/dev/null || true
    ip6tables -t mangle -D FORWARD -i "$_if" -p tcp --dport 853 -j DROP 2>/dev/null || true
    ip6tables -t nat -D PREROUTING -i "$_if" -p udp --dport 53 -j REDIRECT --to-ports 53 2>/dev/null || true
    ip6tables -t nat -D PREROUTING -i "$_if" -p tcp --dport 53 -j REDIRECT --to-ports 53 2>/dev/null || true
done

# 4. REDIRECT DNS (53) + Блокировка DoT (853) для IPv4 и IPv6
for _if in wlan+ ap+ swlan+ softap+ rndis+ usb+ bt-pan+ pan+; do
    iptables -t nat -A PREROUTING -i "$_if" -p udp --dport 53 -j REDIRECT --to-ports 53 2>/dev/null || true
    iptables -t nat -A PREROUTING -i "$_if" -p tcp --dport 53 -j REDIRECT --to-ports 53 2>/dev/null || true
    iptables -t mangle -A FORWARD -i "$_if" -p tcp --dport 853 -j DROP 2>/dev/null || true

    ip6tables -t nat -A PREROUTING -i "$_if" -p udp --dport 53 -j REDIRECT --to-ports 53 2>/dev/null || true
    ip6tables -t nat -A PREROUTING -i "$_if" -p tcp --dport 53 -j REDIRECT --to-ports 53 2>/dev/null || true
    ip6tables -t mangle -A FORWARD -i "$_if" -p tcp --dport 853 -j DROP 2>/dev/null || true
done

# 5. Защита от NTP на IPv4 и IPv6
for _if in wlan+ ap+ swlan+ softap+ rndis+ usb+ bt-pan+ pan+; do
    if [ "$DEBUG_MODE" -eq 1 ]; then
        iptables -t mangle -A FORWARD -i "$_if" -p udp --dport 123 -j LOG --log-prefix "NFQTTL-NTP-BLOCK: " 2>/dev/null || true
    fi
    iptables -t mangle -A FORWARD -i "$_if" -p udp --dport 123 -j DROP 2>/dev/null || true
    ip6tables -t mangle -A FORWARD -i "$_if" -p udp --dport 123 -j DROP 2>/dev/null || true
done

# 6. Динамический парсинг и подгрузка блокировок из blocklist.txt (IPv4 & IPv6)
BLOCKLIST_FILE="$MODDIR/blocklist.txt"
HAS_IP6_STRING=0
if grep -q string /proc/net/ip6_tables_matches 2>/dev/null; then
    HAS_IP6_STRING=1
fi

if [ -f "$BLOCKLIST_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        domain=$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr -d '\r')
        [ -z "$domain" ] && continue

        for _if in wlan+ ap+ swlan+ softap+ rndis+ usb+ bt-pan+ pan+; do
            iptables -t mangle -D FORWARD -i "$_if" -m string --string "$domain" --algo bm -j LOG --log-prefix "NFQTTL-BLOCK: " 2>/dev/null || true
            iptables -t mangle -D FORWARD -i "$_if" -m string --string "$domain" --algo bm -j DROP 2>/dev/null || true

            if [ "$DEBUG_MODE" -eq 1 ]; then
                iptables -t mangle -A FORWARD -i "$_if" -m string --string "$domain" --algo bm -j LOG --log-prefix "NFQTTL-BLOCK: " 2>/dev/null || true
            fi
            iptables -t mangle -A FORWARD -i "$_if" -m string --string "$domain" --algo bm -j DROP 2>/dev/null || true

            if [ "$HAS_IP6_STRING" -eq 1 ]; then
                ip6tables -t mangle -D FORWARD -i "$_if" -m string --string "$domain" --algo bm -j DROP 2>/dev/null || true
                ip6tables -t mangle -A FORWARD -i "$_if" -m string --string "$domain" --algo bm -j DROP 2>/dev/null || true
            fi
        done
    done < "$BLOCKLIST_FILE"
fi

# 7. Коррекция TCP MSS (заведена на интерфейсы раздачи и модемы)
for _celnt in rmnet+ rmnet_data+ r_rmnet_data+ rmnet_mhi+ rmnet_ipa+ ccmni+ pdp+; do
    iptables -t mangle -A POSTROUTING -o "$_celnt" -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtud 2>/dev/null || true
done
for _if in wlan+ ap+ swlan+ softap+ rndis+ usb+ bt-pan+ pan+; do
    iptables -t mangle -A POSTROUTING -o "$_if" -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtud 2>/dev/null || true
done

# 8. Фиксация IPv6 Hop Limit = 64 (Kernel HL vs Userspace NFQUEUE)
if grep -q HL /proc/net/ip6_tables_targets 2>/dev/null; then
    for _celnt in rmnet+ rmnet_data+ r_rmnet_data+ rmnet_mhi+ rmnet_ipa+ ccmni+ pdp+; do
        ip6tables -t mangle -A POSTROUTING -o "$_celnt" -j HL --hl-set 64 2>/dev/null || true
    done
    for _if in wlan+ ap+ swlan+ softap+ rndis+ usb+ bt-pan+ pan+; do
        ip6tables -t mangle -A POSTROUTING -o "$_if" -j HL --hl-set 64 2>/dev/null || true
    done
else
    # Режим NFQUEUE для IPv6 Hop Limit = 64
    if ! nfqttl_alive; then
        "$MODDIR/nfqttl" -d
        sleep 1
    fi

    ip6tables -t mangle -N nfqttlo 2>/dev/null || true
    ip6tables -t mangle -F nfqttlo
    ip6tables -t mangle -A nfqttlo -j NFQUEUE --queue-num 6464 --queue-bypass

    for _if in wlan+ ap+ swlan+ softap+ rndis+ usb+ bt-pan+ pan+; do
        ip6tables -t mangle -A POSTROUTING -o "$_if" -j nfqttlo 2>/dev/null || true
    done
fi

# 9. Настройка фиксации TTL (Kernel TTL vs Userspace NFQUEUE)
if grep -q TTL /proc/net/ip_tables_targets 2>/dev/null; then
    # РЕЖИМ 1: Нативный Kernel TTL (0% нагрузки на CPU)
    for _celnt in rmnet+ rmnet_data+ r_rmnet_data+ rmnet_mhi+ rmnet_ipa+ ccmni+ pdp+; do
        iptables -t mangle -A POSTROUTING -o "$_celnt" -j TTL --ttl-set 64 2>/dev/null || true
    done
    for _if in wlan+ ap+ swlan+ softap+ rndis+ usb+ bt-pan+ pan+; do
        iptables -t mangle -A POSTROUTING -o "$_if" -j TTL --ttl-set 64 2>/dev/null || true
    done
else
    # РЕЖИМ 2: Userspace NFQUEUE + Daemon Nfqttl
    if ! nfqttl_alive; then
        "$MODDIR/nfqttl" -d
        sleep 1
    fi

    iptables -t mangle -N nfqttlo 2>/dev/null || true
    iptables -t mangle -F nfqttlo
    iptables -t mangle -A nfqttlo -j NFQUEUE --queue-num 6464 --queue-bypass

    # Направляем в NFQUEUE ТОЛЬКО клиентские интерфейсы раздачи _if!
    for _if in wlan+ ap+ swlan+ softap+ rndis+ usb+ bt-pan+ pan+; do
        iptables -t mangle -A POSTROUTING -o "$_if" -j nfqttlo 2>/dev/null || true
    done

    WD_LOG=/data/local/tmp/nfqttl_watchdog.log
    WD_INTERVAL=20
    WD_MAX_RESTARTS=50

    wd_log() {
        if [ -f "$WD_LOG" ] && [ "$(wc -c < "$WD_LOG" 2>/dev/null || echo 0)" -gt 65536 ]; then
            tail -n 50 "$WD_LOG" > "$WD_LOG.tmp" 2>/dev/null && mv "$WD_LOG.tmp" "$WD_LOG"
        fi
        echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$WD_LOG"
    }

    watchdog() {
        restarts=0
        last_restart_time=$(date +%s 2>/dev/null || echo 0)
        wd_log "watchdog запущен (авто-сброс усталости, контроль ip_forward, интервал ${WD_INTERVAL}с)"

        while true; do
            sleep "$WD_INTERVAL"

            echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true
            echo 1 > /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null || true

            if nfqttl_alive; then
                now=$(date +%s 2>/dev/null || echo 0)
                if [ "$now" -gt 0 ] && [ "$last_restart_time" -gt 0 ]; then
                    elapsed=$((now - last_restart_time))
                    if [ "$elapsed" -ge 600 ] && [ "$restarts" -gt 0 ]; then
                        wd_log "демон стабилен 10+ минут с момента последнего рестарта — сброс счетчика с $restarts до 0"
                        restarts=0
                    fi
                fi
                continue
            fi

            if [ "$restarts" -ge "$WD_MAX_RESTARTS" ]; then
                wd_log "демон мёртв, лимит перезапусков исчерпан — прекращаю попытки"
                break
            fi

            restarts=$((restarts + 1))
            last_restart_time=$(date +%s 2>/dev/null || echo 0)
            wd_log "демон не найден, перезапуск #$restarts"
            "$MODDIR/nfqttl" -d
            sleep 2
        done
    }

    watchdog &
fi

# 10. Отладочный режим: если есть файл debug или DEBUG — автоматически генерируем nfqttl_debug.log
if [ "$DEBUG_MODE" -eq 1 ]; then
    if [ -f "$MODDIR/debug_log.sh" ]; then
        sh "$MODDIR/debug_log.sh" >/dev/null 2>&1 &
    fi
fi

exit 0
