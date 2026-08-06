# Список изменений (Changelog)

## Версия v6.3 (Критическое решение проблем OnePlus 13 и Android 7.1.2)

* :rocket: **Исправление режима NFQUEUE для OnePlus 13 (Android 15 / OxygenOS):** В ядрах, где отсутствует нативный таргетинг TTL (как на OnePlus 13), перехват NFQUEUE теперь принудительно накрывает все точки доступа (`wlan+`, `ap+`, `swlan+`) и сотовые модемы (`rmnet+`, `r_rmnet_data+`) в POSTROUTING.
* :package: **Совместимость ZIP-архиватора с Android 7.1.2:** Архивация переведена на классический универсальный ZIP-формат, 100% поддерживаемый всеми версиями `busybox unzip` на старых Android 7.1.2 / Magisk v20.4 (решена ошибка `unzip error`).
* :lock: **Усиленный запуск IP Forwarding:** Автоматическое включение форвардинга через прямое перенаправление `/proc/sys/net/ipv4/ip_forward`.

## Версия v6.2

* :rocket: Отключение Tethering Hardware Offload и строгая фиксация TTL=64 в POSTROUTING.

## Версия v6.1

* :shield: Перехват входящего TTL=1 на PREROUTING и автоматический DNS REDIRECT.

## Версия v6.0 (Мажорный релиз)

* :zap: Отладка по дефолту ВЫКЛЮЧЕНА (Zero-overhead). Кнопка «Действие / Action» в Root-менеджере.
