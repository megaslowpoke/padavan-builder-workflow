#!/bin/bash
set -e
# Подгружаем переменные из конфига сборки
source build.config
TRUNK="padavan-ng/trunk"
OVER_TRUNK="overlay/trunk"
OVER_NOUSB_TRUNK="overlay_NOUSB/trunk"
WEB_DIR="padavan-ng/trunk/user/www/n56u_ribbon_fixed"

# Обновляем корневые сертификаты с помощью родного скрипта, если включен хотя бы один зависимый сервис
if [ "$CONFIG_FIRMWARE_INCLUDE_STUBBY" = "y" ] || \
   [ "$CONFIG_FIRMWARE_INCLUDE_DOH" = "y" ] || \
   [ "$CONFIG_FIRMWARE_INCLUDE_OPENVPN" = "y" ] || \
   [ "$CONFIG_FIRMWARE_INCLUDE_CURL" = "y" ] || \
   [ "$CONFIG_FIRMWARE_INCLUDE_HTTPS" = "y" ] || \
   [ "$CONFIG_FIRMWARE_INCLUDE_SFTP" = "y" ] || \
   [ "$CONFIG_FIRMWARE_INCLUDE_EAP_PEAP" = "y" ] || \
   [ "$CONFIG_FIRMWARE_INCLUDE_DDNS_SSL" = "y" ] || \
   [ "$CONFIG_FIRMWARE_INCLUDE_SSWAN" = "y" ]; then
    (
        cd "$TRUNK/libs/libssl" || exit 2
        chmod +x ca-certificates_update.sh
        ./ca-certificates_update.sh || exit 2
    )
fi

# Фикс сборки libgetdns (Stubby, DoT) при использовании OpenSSL 1.1.1w
if [ "$CONFIG_FIRMWARE_INCLUDE_OPENSSL_11" = "y" ] && [ "$CONFIG_FIRMWARE_INCLUDE_STUBBY" = "y" ]; then
    grep -rl "SSL_get1_peer_certificate" "$TRUNK/libs/libgetdns" | xargs -r sed -i 's/SSL_get1_peer_certificate/SSL_get_peer_certificate/g'
fi

# Часовой пояс, по умолчанию стоит Киев
TZ=UTC-3    # Москва
# TZ=UCT-3_1  # Минск
# TZ=IST-3IDT # Багдад
# TZ=UCT-3_2  # Найроби
sed -i "s/.*\"time_zone\".*/\t{ \"time_zone\", \"$TZ\" },/" "$TRUNK/user/shared/defaults.c"

# Язык веб-интерфейса
# sed -i 's/.*"web_ui_lang".*/\t{ "web_ui_lang", "RU" },/' "$TRUNK/user/shared/defaults.c"

# NTP-серверы
# "time100.stupi.se", "ntp1.vniiftri.ru", "time.esa.int", "ojab.ru", "ntp.ix.ru", "ntp.msk-ix.ru", "ru.pool.ntp.org", "time.cloudflare.com"
sed -i 's/#define DEF_NTP_SERVER0.*/#define DEF_NTP_SERVER0 "ntp.ix.ru"/' "$TRUNK/user/shared/defaults.h"
sed -i 's/#define DEF_NTP_SERVER1.*/#define DEF_NTP_SERVER1 "ntp.msk-ix.ru"/' "$TRUNK/user/shared/defaults.h"
sed -i 's/#define DEF_NTP_SERVER2.*/#define DEF_NTP_SERVER2 "ru.pool.ntp.org"/' "$TRUNK/user/shared/defaults.h"
sed -i 's/#define DEF_NTP_SERVER3.*/#define DEF_NTP_SERVER3 "time100.stupi.se"/' "$TRUNK/user/shared/defaults.h"
# замена дефолтных нтп при обновлении настроек в обход дот/дох/днскрипт
sed -i 's|server=/ntp.org/time.cloudflare.com/time.google.com/time.in.ua/1.1.1.1|server=/ntp.ix.ru/ntp.msk-ix.ru/ru.pool.ntp.org/time.cloudflare.com/time100.stupi.se/ntp1.vniiftri.ru/ojab.ru/time.esa.int/185.228.168.9|' "$TRUNK/user/scripts/mtd_storage.sh"

# Логин и пароль от веб-интерфейса и SSH
sed -i 's/.*"http_username".*/\t{ "http_username", "admin" },/' "$TRUNK/user/shared/defaults.c"
sed -i 's/.*"http_passwd".*/\t{ "http_passwd", "" },/' "$TRUNK/user/shared/defaults.c"
# SSH по умолчанию
# sed -i 's/.*"sshd_enable".*/\t{ "sshd_enable", "1" },/' "$TRUNK/user/shared/defaults.c"

# Сеть и Wi-Fi
NEW_LAN="192.168.10"
# DHCP
sed -i "s/#define DEF_LAN_ADDR.*/#define DEF_LAN_ADDR \"$NEW_LAN.1\"/" "$TRUNK/user/shared/defaults.h"
sed -i "s/#define DEF_LAN_DHCP_BEG.*/#define DEF_LAN_DHCP_BEG \"$NEW_LAN.100\"/" "$TRUNK/user/shared/defaults.h"
sed -i "s/#define DEF_LAN_DHCP_END.*/#define DEF_LAN_DHCP_END \"$NEW_LAN.199\"/" "$TRUNK/user/shared/defaults.h"
# Скрипт создания дефолтных пользовательских файлов (меняем примеры SOCKS, DHCP, Hosts)
sed -i "s/192\.168\.1\.1:9050/$NEW_LAN.1:9050/g" "$TRUNK/user/scripts/mtd_storage.sh"
sed -i "s/192\.168\.1\.10,/$NEW_LAN.10,/g" "$TRUNK/user/scripts/mtd_storage.sh"
sed -i "s/192\.168\.1\.100/$NEW_LAN.100/g" "$TRUNK/user/scripts/mtd_storage.sh"
# Серые HTML-подсказки в полях ввода LAN/AP
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/Advanced_LAN_Content.asp"
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/Advanced_APLAN_Content.asp"
# JS-функция сброса настроек и языковые подсказки
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/Advanced_SettingBackup_Content.asp"
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/Restarting.asp"
sed -i "s/192.168.1\./$NEW_LAN./g" "$TRUNK/user/www/dict"/*.{dict,footer}
# Валидация данных
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/validator.js"
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/general.js"

# По дефолту Wi-Fi скрытый
sed -i 's/.*"rt_closed".*/\t{ "rt_closed", "1" },/' "$TRUNK/user/shared/defaults.c"
sed -i 's/.*"wl_closed".*/\t{ "wl_closed", "1" },/' "$TRUNK/user/shared/defaults.c"
# Региональные настройки Wi-Fi
sed -i 's/.*"rt_country_code".*/\t{ "rt_country_code", "RU" },/' "$TRUNK/user/shared/defaults.c"
sed -i 's/.*"wl_country_code".*/\t{ "wl_country_code", "RU" },/' "$TRUNK/user/shared/defaults.c"

# Obtaining DNS from VPN Server: Add to existing list
sed -i 's/.*"vpnc_pdns".*/\t{ "vpnc_pdns", "1" },/' "$TRUNK/user/shared/defaults.c"
# Restrict Access from VPN Server Site: Yes, but follow Firewall & Port Forwarding rules
sed -i 's/.*"vpnc_sfw".*/\t{ "vpnc_sfw", "3" },/' "$TRUNK/user/shared/defaults.c"
# WebUI syslog float panel mode - Last 100 lines
sed -i 's/.*"log_float_ui".*/\t{ "log_float_ui", "2" },/' "$TRUNK/user/shared/defaults.c"
# Software Offload TCP/UDP for LAN/WLAN
sed -i 's/.*"sfe_enable".*/\t{ "sfe_enable", "2" },/' "$TRUNK/user/shared/defaults.c"
# ZAPRET
sed -i 's/.*"zapret_enable".*/\t{ "zapret_enable", "1" },/' "$TRUNK/user/shared/defaults.c"
# VLMCSD
sed -i 's/.*"vlmcsd_enable".*/\t{ "vlmcsd_enable", "1" },/' "$TRUNK/user/shared/defaults.c"
# watchdog_cpu
sed -i 's/.*"watchdog_cpu".*/\t{ "watchdog_cpu", "1" },/' "$TRUNK/user/shared/defaults.c"
# dhcp_stop_dns_rebind
sed -i 's/.*"dhcp_stop_dns_rebind".*/\t{ "dhcp_stop_dns_rebind", "1" },/' "$TRUNK/user/shared/defaults.c"
# dhcp_proxy_dnssec
sed -i 's/.*"dhcp_proxy_dnssec".*/\t{ "dhcp_proxy_dnssec", "1" },/' "$TRUNK/user/shared/defaults.c"
# lltd
sed -i 's/.*"lltd_enable".*/\t{ "lltd_enable", "1" },/' "$TRUNK/user/shared/defaults.c"
# DNSCRYPT
sed -i 's/.*"dnscrypt_enable".*/\t{ "dnscrypt_enable", "1" },/' "$TRUNK/user/shared/defaults.c"
# Настройки DNS
sed -i 's/.*"redirect_all_dns".*/\t{ "redirect_all_dns", "1" },/' "$TRUNK/user/shared/defaults.c"
sed -i 's/.*"dhcp_strict_order".*/\t{ "dhcp_strict_order", "1" },/' "$TRUNK/user/shared/defaults.c"
sed -i 's/.*"dnscrypt_force_dns".*/\t{ "dnscrypt_force_dns", "1" },/' "$TRUNK/user/shared/defaults.c"
# ez_action_long, выключение ролтона по долгому нажатию на WPS
sed -i 's/.*"ez_action_long".*/\t{ "ez_action_long", "8" },/' "$TRUNK/user/shared/defaults.c"
# Сохранение настроек
sed -i 's/.*"nvram_manual".*/\t{ "nvram_manual", "1" },/' "$TRUNK/user/shared/defaults.c"
sed -i 's/.*"rstats_enable".*/\t{ "rstats_enable", "0" },/' "$TRUNK/user/shared/defaults.c"
sed -i 's/.*"rstats_stored".*/\t{ "rstats_stored", "0" },/' "$TRUNK/user/shared/defaults.c"
sed -i 's/.*"stime_stored".*/\t{ "stime_stored", "1" },/' "$TRUNK/user/shared/defaults.c"

# Комментируем дефолтные серверы в шаблоне Stubby и добавляем свои
if [ "$CONFIG_FIRMWARE_INCLUDE_STUBBY" = "y" ]; then
    sed -i '/## Cloudflare/,/tls_auth_name: "dns.google"/c\
## Cloudflare\
#  - address_data: 1.1.1.1\
#    tls_auth_name: "cloudflare-dns.com"\
#  - address_data: 1.0.0.1\
#    tls_auth_name: "cloudflare-dns.com"\
## Google\
#  - address_data: 8.8.8.8\
#    tls_auth_name: "dns.google"\
#  - address_data: 8.8.4.4\
#    tls_auth_name: "dns.google"\
## CleanBrowsing Security\
  - address_data: 185.228.168.9\
    tls_auth_name: "security-filter-dns.cleanbrowsing.org"\
  - address_data: 185.228.169.9\
    tls_auth_name: "security-filter-dns.cleanbrowsing.org"\
## DNS.SB (Stealth)\
  - address_data: 45.11.45.11\
    tls_auth_name: "dot.sb"\
  - address_data: 185.222.222.222\
    tls_auth_name: "dot.sb"' "$TRUNK/user/stubby/stubby_proxy.sh"
fi

# Автосмена UDP-порта wg0 (AmneziaWG / WireGuard) через vpnc_server_script.sh
if [ "$CONFIG_FIRMWARE_INCLUDE_AMNEZIAWG" = "y" ] || [ "$CONFIG_FIRMWARE_INCLUDE_WIREGUARD" = "y" ]; then
    grep -q 'chmod 755 "\$script_vpnc"' "$TRUNK/user/scripts/mtd_storage.sh" || exit 2
    sed -i '/chmod 755 "\$script_vpnc"/i \
\t\tcat >> "$script_vpnc" << '\''WG_EOF'\''\
\
if [ "$IFNAME" = "wg0" ]; then\
  case "$1" in\
  up|start)\
    killall -q wg_watchdog.sh\
    cat << '\''WD_EOF'\'' > /tmp/wg_watchdog.sh\
#!/bin/sh\
PATTERN="(amneziawg|wireguard): wg0: Handshake .* did not complete"\
LAST_ERR=$(grep -E "$PATTERN" /tmp/syslog.log 2>/dev/null | tail -n 1)\
while sleep 15; do\
    [ -d /sys/class/net/wg0 ] || exit 0\
    ERR=$(grep -E "$PATTERN" /tmp/syslog.log 2>/dev/null | tail -n 1)\
    if [ -n "$ERR" ] \&\& [ "$ERR" != "$LAST_ERR" ]; then\
        logger -t wg_watchdog "Handshake timeout detected, rotating wg0 UDP port"\
        case "$ERR" in\
            *amneziawg:*) awg set wg0 listen-port 0 ;;\
            *wireguard:*) wg set wg0 listen-port 0 ;;\
        esac\
        sleep 6\
        ERR=$(grep -E "$PATTERN" /tmp/syslog.log 2>/dev/null | tail -n 1)\
    fi\
    LAST_ERR="$ERR"\
done\
WD_EOF\
    chmod +x /tmp/wg_watchdog.sh\
    /tmp/wg_watchdog.sh \&\
    ;;\
  down|stop)\
    killall -q wg_watchdog.sh\
    ;;\
  esac\
fi\
WG_EOF' "$TRUNK/user/scripts/mtd_storage.sh"
fi

# === Надо облегчить прошивку, не влезает в 4мб дир300 ===

# Оставляем шапку и основные серверы в списке dnscrypt
# sed -i -n '1p; /cisco\|cleanbrowsing\|quad9\|dnscrypt\.eu\|adguard/p' \
# "$TRUNK/user/dnscrypt-proxy/dnscrypt-proxy-1.9.5/dnscrypt-resolvers.csv"

# Очищаем веб-интерфейс (asp/js/css/htm) от начальных пробелов/табов, пустых строк и однострочных JS-комментариев
find "$WEB_DIR" -type f \( -name "*.asp" -o -name "*.htm" -o -name "*.js" -o -name "*.css" \) \
    ! -name "*.min.css" \( ! -name "*.min.js" -o -name "engage.itoggle.min.js" \) \
    -exec sed -i \
        -e 's/^[[:space:]]*//' \
        -e '/^[[:space:]]*\/\//d' \
        -e 's/[[:space:]]*$//' \
        -e '/^$/d' {} +

# Исключаем сборку infosvr/lanauth/ddns из общего Makefile
sed -i '/\<infosvr\>/d; /\<lanauth\>/d; /\<inadyn\>/d' "$TRUNK/user/Makefile"
# Убираем создание конфига inadyn.conf в /etc/storage при инициализации
sed -i '/# create user inadyn\.conf/,/# create user hosts/{/# create user hosts/!d;}' "$TRUNK/user/scripts/mtd_storage.sh"
# Убираем вкладку DDNS из меню WAN (state.js) и карты сети (internet.asp)
sed -i '/Advanced_DDNS_Content\.asp/d' "$WEB_DIR/device-map/internet.asp"
sed -i 's/, "Advanced_DDNS_Content\.asp"//' "$WEB_DIR/state.js"
sed -i 's/, "<#menu5_3_6#>"//' "$WEB_DIR/state.js"
# Вырезаем JS-обработчики DDNS из start_apply.htm и general.js
sed -i '/action_script\.indexOf("hostname_check")/,/else if(page_modified == 1)/{/else if(page_modified == 1)/!d;}' "$WEB_DIR/start_apply.htm"
sed -i '/function validate_ddns_hostname/,/function validate_hostnamechar/{/function validate_hostnamechar/!d;}' "$WEB_DIR/general.js"
sed -i '/current_page\.value == "Advanced_DDNS_Content\.asp"/,/action_mode\.value = "Update"/{/action_mode\.value = "Update"/!d;}' "$WEB_DIR/general.js"
# Убираем из словарей почти всё про DDNS
sed -i -E '/^(DDNS|LANHostConfig_x_DDNS([A-Za-z]|_alarm_([1-8]|1[0-4]|hostname|registered))|noDDNS=|neednotDDNS=|asusddns_inputhint=|menu5_3_6=)/d' "$TRUNK/user/www/dict"/*.{dict,footer}
# И про диски
sed -i -E '/^(AiDisk|File_Pop_content_alert_desc|File_content_alert_desc|ALERT_OF_ERROR_|HowToShareby|Storage[A-Z]|HSDPAConfig_|Modem|Printer|OVPN_)/d' "$TRUNK/user/www/dict"/*.{dict,footer}
# Убираем 'ISP KABiNET' из выпадающего списка авторизации WAN
sed -i '/value="1".*ISP KABiNET/d' "$WEB_DIR/Advanced_WAN_Content.asp"
# Скрываем в asp блок с infosvr
sed -i '/<tr>/{
  $!N
  /<tr>[[:space:]]*<th><#Adm_Svc_adsc#><\/th>/ s/<tr>/<tr style="display:none;">/
  P; D
}' "$WEB_DIR/Advanced_Services_Content.asp"

# --- Скрипт финальной очистки romfs перед упаковкой в SquashFS ---
cat << 'EOF' >> "$TRUNK/tools/strip-romfs.sh"
echo "=== [CUSTOM CLEAN] Cleaning extra files in $ROMFSDIR ==="
EOF
# terminfo
cat << 'EOF' >> "$TRUNK/tools/strip-romfs.sh"
rm -rfv "$ROMFSDIR/usr/share/terminfo/a" \
        "$ROMFSDIR/usr/share/terminfo/d" \
        "$ROMFSDIR/usr/share/terminfo/s" \
        "$ROMFSDIR/usr/share/terminfo/v/vt220" \
        "$ROMFSDIR/usr/share/terminfo/x/xterm-color" \
        "$ROMFSDIR/usr/share/terminfo/x/xterm-r6" \
        "$ROMFSDIR/usr/share/terminfo/x/xterm-xfree86" \
        "$ROMFSDIR/usr/share/terminfo/screen" \
        "$ROMFSDIR/usr/share/terminfo/vt200" \
        "$ROMFSDIR/usr/share/terminfo/xterm-color"
EOF
# ico
cat << 'EOF' >> "$TRUNK/tools/strip-romfs.sh"
rm -rfv "$ROMFSDIR/etc_ro/icon.ico" \
        "$ROMFSDIR/etc_ro/icon.large.ico" \
        "$ROMFSDIR/www/images/favicon.ico"
EOF
# qrcode
cat << 'EOF' >> "$TRUNK/tools/strip-romfs.sh"
rm -rfv "$ROMFSDIR/www/qrcode.min.js"
EOF
# disk
cat << 'EOF' >> "$TRUNK/tools/strip-romfs.sh"
rm -rfv "$ROMFSDIR/www/disk_functions.js" \
        "$ROMFSDIR/www/bootstrap/img/icons/aidisk"
EOF
# DDNS
cat << 'EOF' >> "$TRUNK/tools/strip-romfs.sh"
rm -rfv "$ROMFSDIR/www/Advanced_DDNS_Content.asp" \
        "$ROMFSDIR/sbin/ddns_updated" \
        "$ROMFSDIR/sbin/start_ddns"
EOF

# Накатываем свои оптимизированные файлы (без скрытых файлов, иначе: '"$OVER_TRUNK"/. "$TRUNK/".')
if [ -d "$OVER_TRUNK" ]; then
   if [ "$CONFIG_FIRMWARE_ENABLE_USB" = "y" ]; then
      cp -rf "$OVER_TRUNK"/* "$TRUNK/"
   else
      cp -rf "$OVER_NOUSB_TRUNK"/* "$TRUNK/"
   fi
fi

# --- Предзаполнение файла маршрутов VPN для новых роутеров ---
cat << 'VPN_EOF' >> "$TRUNK/user/scripts/autostart.sh"

# Заполняем список сетей VPN при первой загрузке роутера
VPNC_LIST="/etc/storage/vpnc_remote_network.list"
if [ ! -f "/etc/storage/.vpnc_inited" ]; then
    cat << 'VPN_LIST_EOF' > "$VPNC_LIST"
# Адрес проверки IP через тоннель: https://ifconfig.me/ или только IP: https://ifconfig.me/ip
34.160.111.145/32
# Телеграм:
VPN_EOF

# Пытаемся скачать актуальный список сетей Telegram напрямую в файл autostart.sh
echo "Скачиваем актуальный список CIDR Telegram..."
if ! curl -sSfL "https://core.telegram.org/resources/cidr.txt" >> "$TRUNK/user/scripts/autostart.sh"; then
    echo "Ошибка скачивания. Используем резервный список."
    cat << 'FALLBACK_EOF' >> "$TRUNK/user/scripts/autostart.sh"
5.28.192.0/21
5.28.248.0/21
91.105.192.0/23
91.108.4.0/22
91.108.8.0/21
91.108.16.0/21
91.108.36.0/22
91.108.56.0/22
95.161.64.0/20
149.154.160.0/20
185.76.151.0/24
2001:b28:f23d::/48
2001:b28:f23f::/48
2001:67c:4e8::/48
2001:b28:f23c::/48
2a0a:f280::/32
FALLBACK_EOF
else
    echo "" >> "$TRUNK/user/scripts/autostart.sh" # Добавляем перенос строки на всякий случай
fi

# Дописываем закрывающую часть скрипта
cat << 'VPN_EOF' >> "$TRUNK/user/scripts/autostart.sh"
VPN_LIST_EOF
    touch "/etc/storage/.vpnc_inited"
    mtd_storage.sh save >/dev/null 2>&1
fi
VPN_EOF
