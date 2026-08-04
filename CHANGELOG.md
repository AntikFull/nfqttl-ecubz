# Список изменений (Changelog)

## Версия v6.0 (Мажорный релиз)

* <i class="material-icons">bolt</i> **Отладка по дефолту ВЫКЛЮЧЕНА (Zero-overhead):** В стандартном релизе отладочный режим не активен, память не засирается.
* <i class="material-icons">tune</i> **Кнопка «Действие / Action» в Root-менеджере:** Прямо в KernelSU / APatch / Magisk вы можете нажать кнопку «Действие» напротив модуля — отладочный режим включится/выключится в 1 клик прямо из граф-интерфейса!
* <i class="material-icons">rocket_launch</i> **Универсальная поддержка OnePlus (ColorOS / OxygenOS), Realme, Oppo, Xiaomi, MTK и Qualcomm:** Полная поддержка специфических сетевых интерфейсов раздачи (`ap+`, `swlan+`, `softap+`, `rndis+`, `bt-pan+`) и каналов данных модемов (`r_rmnet_data+`, `rmnet_mhi+`, `rmnet_ipa+`, `ccmni+`).
* <i class="material-icons">format_list_bulleted</i> **Пользовательский `blocklist.txt`:** Возможность добавлять любые домены/подстроки для блокировки детекции.
* <i class="material-icons">block</i> **Защита от «Анти-TTL МТС»:** Автоматическая нейтрализация Windows NCSI, системного времени и NTP (123 UDP).
* <i class="material-icons">psychology</i> **Умный авто-выбор движка:** Kernel TTL vs Userspace NFQUEUE.
* <i class="material-icons">shield</i> **Безопасная обработка IPv6:** Защита от утечки IPv6 TTL.

## Версия v5.7

* <i class="material-icons">rocket_launch</i> Мульти-вендорные сетевые интерфейсы раздачи и модемов.

## Версия v5.6

* <i class="material-icons">bug_report</i> Авто-выдача прав 0755 на скрипты в installer.

## Версия v5.5

* <i class="material-icons">search</i> Логирование палящего трафика в `nfqttl_debug.log`.

## Версия v5.0

* <i class="material-icons">bug_report</i> Устранены SIGSEGV краши в C-коде.
* <i class="material-icons">bolt</i> Совместимость с KSU / APatch / Magisk.
