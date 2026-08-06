# Список изменений (Changelog)

## Версия v7.8 (Мажорный Релиз: Снайперская защита от детекции МТС по TTL=1)

### 🔴 Бескомпромиссный обход детекции МТС без блокировки интернета:
* 🎯 **Настоящая защита от детекции TTL=1 от МТС (ICMP Time Exceeded Drop):**
  Оператор МТС засекает раздачу, посылая пакеты с TTL=1 и ловя обратно от смартфона служебное сообщение **ICMP Time Exceeded (Type 11)** при форвардинге на клиентские устройства.
  В `v7.8` добавлена блокировка исходящих ответов `ICMP Time Exceeded` на сотовые модемы (`_celnt`):
  `iptables -t filter -A OUTPUT -o "$_celnt" -p icmp --icmp-type time-exceeded -j DROP`
  `ip6tables -t filter -A OUTPUT -o "$_celnt" -p icmpv6 --icmpv6-type time-exceeded -j DROP`
* 🛡 **Снайперский FORWARD TTL=1:**
  Фильтрация входящих проб `TTL=1` перенесена исключительно в цепочку `FORWARD` (`iptables -t mangle -A FORWARD -i "$_celnt" -m ttl --ttl-eq 1 -j DROP`).
  Собственные входящие ответы интернета для смартфона в `INPUT`/`PREROUTING` больше не задеваются и вылетают на 100% максимальной скорости!
