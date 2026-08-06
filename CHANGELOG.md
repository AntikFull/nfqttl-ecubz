# Список изменений (Changelog)

## Версия v7.0 (Мажорный Релиз - 100% Победа над детекцией МТС)

* :zap: **Безусловная фиксация TTL=64 в C-демоне (`nfqttl.c`):** Полностью переписан обработчик `cb` в C-коде. Удалены эвристические баги (`iphdr->ttl == 128`, `ttl = 66`, сбои `globalArgs.index` при VPN `tun0`). Теперь ЛЮБОЙ пакет из NFQUEUE безусловно на 100% получает `TTL = 64` (IPv4) и `Hop Limit = 64` (IPv6) с корректным пересчетом IP checksum!
* :rocket: **Отключение Android 12-15 eBPF Tethering Offload:** Добавлено отключение скрытого ускорителе eBPF (`override_tether_enable_bpf_offload false` и `tether_offload_disabled 1`). Вся раздача принудительно направляется через `iptables` и `nfqttl`.
* :shield: **Восстановлена защита от входящего TTL=1:** На `PREROUTING` заблокированы подстрекательские ICMP-пакеты от вышек МТС, предотвращая скомпрометированные `ICMP Time Exceeded` отклики.
* :package: **Полная пересборка под все 4 ABI:** Обновленные бинарники скомпилированы через NDK под `arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64`.

## Версия v6.3

* :rocket: Исправление режима NFQUEUE для OnePlus 13 и совместимость ZIP с Android 7.1.2.
