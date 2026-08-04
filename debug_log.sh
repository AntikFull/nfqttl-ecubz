#!/system/bin/sh
MODDIR=${0%/*}
LOGFILE="$MODDIR/nfqttl_debug.log"

echo "==================================================================" > "$LOGFILE"
echo " Nfqttl eCubz Deep Diagnostic & Trace Log" >> "$LOGFILE"
echo " Date: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOGFILE"
echo "==================================================================" >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "--- 1. MODULE & SYSTEM METADATA ---" >> "$LOGFILE"
if [ -f "$MODDIR/module.prop" ]; then
    cat "$MODDIR/module.prop" >> "$LOGFILE"
fi
echo "Device Model: $(getprop ro.product.model)" >> "$LOGFILE"
echo "Android Release: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))" >> "$LOGFILE"
echo "CPU ABI: $(getprop ro.product.cpu.abi)" >> "$LOGFILE"
echo "Kernel: $(uname -a)" >> "$LOGFILE"
echo "SELinux Mode: $(getenforce 2>/dev/null || echo unknown)" >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "--- 2. DAEMON BINARY & STARTUP DIAGNOSTICS ---" >> "$LOGFILE"
if [ -x "$MODDIR/nfqttl" ]; then
    echo "Binary exists: $MODDIR/nfqttl (Executable)" >> "$LOGFILE"
    ls -l "$MODDIR/nfqttl" >> "$LOGFILE" 2>&1
else
    echo "CRITICAL ERROR: Binary $MODDIR/nfqttl is MISSING or NOT EXECUTABLE!" >> "$LOGFILE"
fi

echo "" >> "$LOGFILE"
echo "--- 3. KERNEL NETFILTER CAPABILITIES ---" >> "$LOGFILE"
echo "IPv4 Targets: $(cat /proc/net/ip_tables_targets 2>/dev/null | tr '\n' ' ')" >> "$LOGFILE"
echo "IPv6 Targets: $(cat /proc/net/ip6_tables_targets 2>/dev/null | tr '\n' ' ')" >> "$LOGFILE"
echo "Netfilter Matches: $(cat /proc/net/ip_tables_matches 2>/dev/null | tr '\n' ' ')" >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "--- 4. ACTIVE PROCESSES & NFQUEUE SEARCH ---" >> "$LOGFILE"
ps -A | grep -E "nfqttl|magisk|ksu|apatch" >> "$LOGFILE" 2>&1 || echo "No matching processes" >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "--- 5. ACTIVE NETWORK INTERFACES ---" >> "$LOGFILE"
ip link show >> "$LOGFILE" 2>&1 || ifconfig >> "$LOGFILE" 2>&1

echo "" >> "$LOGFILE"
echo "--- 6. IP FORWARDING & IPV6 SYSCTL SETTINGS ---" >> "$LOGFILE"
echo "net.ipv4.ip_forward = $(sysctl -n net.ipv4.ip_forward 2>/dev/null)" >> "$LOGFILE"
echo "net.ipv6.conf.all.disable_ipv6 = $(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)" >> "$LOGFILE"
echo "net.ipv6.conf.all.forwarding = $(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null)" >> "$LOGFILE"

echo "" >> "$LOGFILE"
echo "--- 7. IPTABLES MANGLE RULES WITH PACKET COUNTERS ---" >> "$LOGFILE"
echo "[IPv4 Mangle PREROUTING]" >> "$LOGFILE"
iptables -t mangle -L PREROUTING -n -v >> "$LOGFILE" 2>&1
echo "[IPv4 Mangle FORWARD]" >> "$LOGFILE"
iptables -t mangle -L FORWARD -n -v >> "$LOGFILE" 2>&1
echo "[IPv4 Mangle POSTROUTING]" >> "$LOGFILE"
iptables -t mangle -L POSTROUTING -n -v >> "$LOGFILE" 2>&1

echo "" >> "$LOGFILE"
echo "--- 8. IP6TABLES RULES WITH PACKET COUNTERS ---" >> "$LOGFILE"
echo "[IPv6 Mangle FORWARD]" >> "$LOGFILE"
ip6tables -t mangle -L FORWARD -n -v >> "$LOGFILE" 2>&1
echo "[IPv6 Mangle POSTROUTING]" >> "$LOGFILE"
ip6tables -t mangle -L POSTROUTING -n -v >> "$LOGFILE" 2>&1

echo "" >> "$LOGFILE"
echo "--- 9. CUSTOM BLOCKLIST CONFIGURATION ---" >> "$LOGFILE"
if [ -f "$MODDIR/blocklist.txt" ]; then
    cat "$MODDIR/blocklist.txt" >> "$LOGFILE"
else
    echo "blocklist.txt NOT FOUND!" >> "$LOGFILE"
fi

echo "" >> "$LOGFILE"
echo "--- 10. WATCHDOG & DAEMON ERROR LOGS ---" >> "$LOGFILE"
if [ -f "/data/local/tmp/nfqttl_watchdog.log" ]; then
    tail -n 50 /data/local/tmp/nfqttl_watchdog.log >> "$LOGFILE" 2>&1
else
    echo "No watchdog log available" >> "$LOGFILE"
fi

echo "" >> "$LOGFILE"
echo "--- 11. BLOCKED SUSPICIOUS TRAFFIC TRACE (DMESG) ---" >> "$LOGFILE"
dmesg 2>/dev/null | grep -E "NFQTTL-BLOCK|NFQTTL-NTP-BLOCK" | tail -n 50 >> "$LOGFILE" 2>&1
if [ $? -ne 0 ] || [ ! -s "$LOGFILE" ]; then
    echo "No suspicious traffic trace found in kernel dmesg log" >> "$LOGFILE"
fi

echo "" >> "$LOGFILE"
echo "==================================================================" >> "$LOGFILE"
echo " Deep Diagnostic Report Complete: $LOGFILE" >> "$LOGFILE"
echo "==================================================================" >> "$LOGFILE"

chmod 666 "$LOGFILE" 2>/dev/null || true
