# Список изменений (Changelog)

## Версия v6.1

* :shield: **Перехват входящего TTL=1 на PREROUTING:** Добавлен безусловный перехват входящих пакетов с TTL=1 от МТС на всех интерфейсах точки доступа (`wlan+`, `ap+`, `swlan+`, `softap+`, `rndis+`, `bt-pan+`). Это предотвращает отправку устройством разоблачающих `ICMP Time Exceeded` отчетов оператору!
* :lock: **Автоматический DNS REDIRECT (Защита от DNS-детекции):** Запросы портов 53 UDP/TCP с клиентских девайсов принудительно перенаправляются на локальный DNS смартфона (`iptables -t nat -A PREROUTING -j REDIRECT --to-ports 53`), перекрывая DNS-детекцию МТС.
* :smartphone: **Полный анализ лога OnePlus 13 (Android 15 / OxygenOS):** Добавлена глубинная совместимость с точками доступа `wlan2` и сотовым слотом `rmnet_data0` модемов Qualcomm/Oplus.
* :clipboard: **Расширенный `blocklist.txt` по умолчанию:** Добавлены домены `time.nist.gov`, `time.apple.com`, `time.google.com`, `time.android.com` и `connectivitycheck.gstatic.com`.

## Версия v6.0 (Мажорный релиз)

* :zap: **Отладка по дефолту ВЫКЛЮЧЕНА (Zero-overhead):** Память не засирается.
* :control_knobs: **Кнопка «Действие / Action» в Root-менеджере:** Управление логированием в 1 клик.
* :rocket: **Поддержка OnePlus (ColorOS / OxygenOS), Realme, Oppo, Xiaomi, MTK и Qualcomm.**
