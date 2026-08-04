#!/system/bin/sh
MODDIR=${0%/*}
LOGFILE="$MODDIR/nfqttl_debug.log"

echo "==================================================================" > "$LOGFILE"
echo " Nfqttl eCubz Debug & Diagnostic Report" >> "$LOGFILE"
echo " Date: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOGFILE"
echo "==================================================================" >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "--- MODULE INFO ---" >> "$LOGFILE"
if [ -f "$MODDIR/module.prop" ]; then
    cat "$MODDIR/module.prop" >> "$LOGFILE"
fi

echo "" >> "$LOGFILE"
echo "--- DEVICE INFO ---" >> "$LOGFILE"
echo "Device Model: $(getprop ro.product.model)" >> "$LOGFILE"
echo "Android Version: $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk))" >> "$LOGFILE"
echo "CPU Architecture: $(getprop ro.product.cpu.abi)" >> "$LOGFILE"
echo "Kernel Version: $(uname -r)" >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "--- KERNEL IPTABLES TARGETS ---" >> "$LOGFILE"
echo "IPv4 Targets: $(cat /proc/net/ip_tables_targets 2>/dev/null | tr '\n' ' ')" >> "$LOGFILE"
echo "IPv6 Targets: $(cat /proc/net/ip6_tables_targets 2>/dev/null | tr '\n' ' ')" >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "--- DAEMON PROCESS STATUS ---" >> "$LOGFILE"
ps -A | grep nfqttl >> "$LOGFILE" 2>&1 || echo "nfqttl process not running" >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "--- IPTABLES MANGLE FORWARD / POSTROUTING ---" >> "$LOGFILE"
iptables -t mangle -L -n -v >> "$LOGFILE" 2>&1

echo "" >> "$LOGFILE"
echo "--- IP6TABLES MANGLE FORWARD / POSTROUTING ---" >> "$LOGFILE"
ip6tables -t mangle -L -n -v >> "$LOGFILE" 2>&1

echo "" >> "$LOGFILE"
echo "--- BLOCKLIST CONTENT ---" >> "$LOGFILE"
if [ -f "$MODDIR/blocklist.txt" ]; then
    cat "$MODDIR/blocklist.txt" >> "$LOGFILE"
else
    echo "blocklist.txt not found" >> "$LOGFILE"
fi

echo "" >> "$LOGFILE"
echo "--- WATCHDOG LOG (LAST 30 LINES) ---" >> "$LOGFILE"
if [ -f "/data/local/tmp/nfqttl_watchdog.log" ]; then
    tail -n 30 /data/local/tmp/nfqttl_watchdog.log >> "$LOGFILE" 2>&1
else
    echo "No watchdog log found" >> "$LOGFILE"
fi

echo "" >> "$LOGFILE"
echo "==================================================================" >> "$LOGFILE"
echo " Diagnostic Report Generated Successfully: $LOGFILE" >> "$LOGFILE"
echo "==================================================================" >> "$LOGFILE"

chmod 666 "$LOGFILE" 2>/dev/null || true
echo "Log saved to: $LOGFILE"
