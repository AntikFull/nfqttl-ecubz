#!/system/bin/sh
ui_print " "
ui_print " ******************************* "
ui_print " *    Magisk Module NFQTTL     * "
ui_print " *        Version v5.0         * "
ui_print " ******************************* "
ui_print " "

APP_ABI=$(getprop ro.product.cpu.abi)
ui_print " [i] Архитектура устройства: $APP_ABI "

if [ -f "$MODPATH/libs/$APP_ABI/nfqttl" ]; then
    ui_print " [✓] Установка бинарника для $APP_ABI "
    cp -af "$MODPATH/libs/$APP_ABI/nfqttl" "$MODPATH/nfqttl"
elif [ -f "$MODPATH/libs/arm64-v8a/nfqttl" ]; then
    ui_print " [!] Архитектура $APP_ABI не найдена, используем резервный arm64-v8a "
    cp -af "$MODPATH/libs/arm64-v8a/nfqttl" "$MODPATH/nfqttl"
fi

rm -rf "$MODPATH/libs"

set_perm $MODPATH/nfqttl 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755

ui_print " "
ui_print " ******************************* "
ui_print " *      Установка успешна!      * "
ui_print " ******************************* "
ui_print " "
