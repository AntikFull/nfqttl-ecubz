#!/system/bin/sh
ui_print " "
ui_print " ******************************* "
ui_print " *    Magisk Module NFQTTL     * "
ui_print " *        Version v5.0         * "
ui_print " ******************************* "
ui_print " "

set_perm $MODPATH/nfqttl 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755

ui_print " "
ui_print " ******************************* "
ui_print " *      Install Success!       * "
ui_print " ******************************* "
ui_print " "
