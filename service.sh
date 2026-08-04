#!/system/bin/sh
MODDIR=${0%/*}

count=0
while true
do
    if ps -A | grep -v grep | grep -q "$MODDIR/nfqttl"
    then
        break
    fi
    if [ "$count" -ge 8 ]
    then
        $MODDIR/nfqttl -d -s -u
        sleep 2
        break
    fi
    count=$((count+1))
    $MODDIR/nfqttl -d -s -u
    sleep 3
done

iptables -t mangle -D PREROUTING -j nfqttli 2>/dev/null || true
iptables -t mangle -D OUTPUT -j nfqttlo 2>/dev/null || true
ip6tables -t mangle -D PREROUTING -j nfqttli 2>/dev/null || true
ip6tables -t mangle -D POSTROUTING -j nfqttlo 2>/dev/null || true

iptables -t mangle -N nfqttlo 2>/dev/null || true
iptables -t mangle -F nfqttlo
# --queue-bypass: если демон nfqttl умрёт, пакеты пойдут мимо очереди, а не в
# никуда. Без этого флага падение демона = полная потеря связи до перезагрузки
# (подмена TTL при этом отвалится, раздача станет видна оператору — но интернет
# останется). Демон падал с SIGSEGV 8 раз за 22.07, так что это не теория.
iptables -t mangle -A nfqttlo -j NFQUEUE --queue-num 6464 --queue-bypass

iptables -t mangle -D POSTROUTING -o rmnet+ -j nfqttlo 2>/dev/null || true
iptables -t mangle -D POSTROUTING -o rmnet_data+ -j nfqttlo 2>/dev/null || true
iptables -t mangle -D POSTROUTING -o wlan+ -j nfqttlo 2>/dev/null || true
iptables -t mangle -A POSTROUTING -o rmnet+ -j nfqttlo
iptables -t mangle -A POSTROUTING -o rmnet_data+ -j nfqttlo
iptables -t mangle -A POSTROUTING -o wlan+ -j nfqttlo

ip6tables -t mangle -N nfqttlo 2>/dev/null || true
ip6tables -t mangle -F nfqttlo
ip6tables -t mangle -A nfqttlo -j NFQUEUE --queue-num 6464 --queue-bypass

ip6tables -t mangle -D POSTROUTING -o rmnet+ -j nfqttlo 2>/dev/null || true
ip6tables -t mangle -D POSTROUTING -o rmnet_data+ -j nfqttlo 2>/dev/null || true
ip6tables -t mangle -D POSTROUTING -o wlan+ -j nfqttlo 2>/dev/null || true
ip6tables -t mangle -A POSTROUTING -o rmnet+ -j nfqttlo
ip6tables -t mangle -A POSTROUTING -o rmnet_data+ -j nfqttlo
ip6tables -t mangle -A POSTROUTING -o wlan+ -j nfqttlo

# ============================================================================
# Watchdog
# ----------------------------------------------------------------------------
# Штатно service.sh запускает демон один раз при загрузке и больше за ним не
# следит. nfqttl падал с SIGSEGV 8 раз за 22.07 — после каждого падения подмена
# TTL молча переставала работать до перезагрузки.
#
# Проверка намеренно дешёвая: один pgrep раз в 60 с, никаких конвейеров из
# ps|grep|grep. Стоимость — примерно один форк в минуту.
# ============================================================================

WD_LOG=/data/local/tmp/nfqttl_watchdog.log
WD_INTERVAL=60
WD_MAX_RESTARTS=20

wd_log() {
    # лог не даём разрастаться
    if [ -f "$WD_LOG" ] && [ "$(wc -c < "$WD_LOG" 2>/dev/null || echo 0)" -gt 65536 ]; then
        tail -n 50 "$WD_LOG" > "$WD_LOG.tmp" 2>/dev/null && mv "$WD_LOG.tmp" "$WD_LOG"
    fi
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$WD_LOG"
}

# ВАЖНО: KernelSU запускает скрипты модулей с ASH_STANDALONE=1. В этом режиме
# busybox подставляет свои апплеты вместо системных бинарников, а busybox'ный
# `pgrep -x` процесс НЕ находит (проверено: /system/bin/pgrep -x nfqttl -> 3070,
# busybox pgrep -x nfqttl -> пусто). Из-за этого watchdog считал живой демон
# мёртвым и перезапускал его вхолостую раз в минуту.
# Поэтому зовём системный бинарник по абсолютному пути, а если его вдруг нет —
# читаем /proc напрямую, без внешних утилит вообще.
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

watchdog() {
    restarts=0
    wd_log "watchdog запущен (интервал ${WD_INTERVAL}с, лимит ${WD_MAX_RESTARTS} перезапусков)"
    while true; do
        sleep "$WD_INTERVAL"

        nfqttl_alive && continue

        if [ "$restarts" -ge "$WD_MAX_RESTARTS" ]; then
            wd_log "демон мёртв, лимит перезапусков исчерпан — прекращаю попытки"
            wd_log "правила стоят с --queue-bypass, связь работает без подмены TTL"
            break
        fi

        restarts=$((restarts + 1))
        wd_log "демон не найден, перезапуск #$restarts"
        "$MODDIR/nfqttl" -d -s -u
        sleep 3

        if nfqttl_alive; then
            wd_log "перезапуск #$restarts успешен"
        else
            wd_log "перезапуск #$restarts не удался"
        fi
    done
    wd_log "watchdog остановлен"
}

watchdog &

exit 0
