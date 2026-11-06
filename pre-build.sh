#!/bin/bash
set -e
TRUNK="padavan-ng/trunk"
TRUNK_USER="padavan-ng/trunk/user"
WEB_DIR="padavan-ng/trunk/user/www/n56u_ribbon_fixed"
OVER_TRUNK="overlay/trunk"

# Обновляем корневые сертификаты с помощью родного скрипта
(
    cd "$TRUNK/libs/libssl" || exit 2
    chmod +x ca-certificates_update.sh
    ./ca-certificates_update.sh || exit 2
)

# Часовой пояс (MSK-3) Москва
# sed -i 's/.*"time_zone".*/\t{ "time_zone", "UTC-3" },/' "$TRUNK_USER/shared/defaults.c"
# Минск
# sed -i 's/.*"time_zone".*/\t{ "time_zone", "UCT-3_1" },/' "$TRUNK_USER/shared/defaults.c"
# Багдад
# sed -i 's/.*"time_zone".*/\t{ "time_zone", "IST-3IDT" },/' "$TRUNK_USER/shared/defaults.c"
# Найроби
sed -i 's/.*"time_zone".*/\t{ "time_zone", "UCT-3_2" },/' "$TRUNK_USER/shared/defaults.c"

# NTP-серверы
# sed -i 's/.*"ntp_server0".*/\t{ "ntp_server0", "time100.stupi.se" },/' "$TRUNK_USER/shared/defaults.c"
# sed -i 's/.*"ntp_server1".*/\t{ "ntp_server1", "ntp1.vniiftri.ru" },/' "$TRUNK_USER/shared/defaults.c"
# sed -i 's/.*"ntp_server2".*/\t{ "ntp_server2", "time.esa.int" },/' "$TRUNK_USER/shared/defaults.c"
# sed -i 's/.*"ntp_server3".*/\t{ "ntp_server3", "ojab.ru" },/' "$TRUNK_USER/shared/defaults.c"
sed -i 's/#define DEF_NTP_SERVER0.*/#define DEF_NTP_SERVER0 "ntp.ix.ru"/' "$TRUNK_USER/shared/defaults.h"
sed -i 's/#define DEF_NTP_SERVER1.*/#define DEF_NTP_SERVER1 "ntp.msk-ix.ru"/' "$TRUNK_USER/shared/defaults.h"
sed -i 's/#define DEF_NTP_SERVER2.*/#define DEF_NTP_SERVER2 "ru.pool.ntp.org"/' "$TRUNK_USER/shared/defaults.h"
sed -i 's/#define DEF_NTP_SERVER3.*/#define DEF_NTP_SERVER3 "time.cloudflare.com"/' "$TRUNK_USER/shared/defaults.h"
# Дефолтные NTP при обновлении настроек в обход дот/дох
sed -i 's|server=/ntp.org/time.cloudflare.com/time.google.com/time.in.ua/1.1.1.1|server=/ntp.ix.ru/ntp.msk-ix.ru/ru.pool.ntp.org/time.cloudflare.com/time100.stupi.se/ntp1.vniiftri.ru/ojab.ru/time.esa.int/185.228.168.9|' "$TRUNK_USER/scripts/mtd_storage.sh"

# Язык веб-интерфейса
# sed -i 's/.*"web_ui_lang".*/\t{ "web_ui_lang", "RU" },/' "$TRUNK_USER/shared/defaults.c"

# SSH по умолчанию
# sed -i 's/.*"sshd_enable".*/\t{ "sshd_enable", "1" },/' "$TRUNK_USER/shared/defaults.c"

# Логин и пароль от веб-интерфейса и SSH
sed -i 's/.*"http_username".*/\t{ "http_username", "admin" },/' "$TRUNK_USER/shared/defaults.c"
sed -i 's/.*"http_passwd".*/\t{ "http_passwd", "" },/' "$TRUNK_USER/shared/defaults.c"

# Сеть и Wi-Fi
NEW_LAN="192.168.10"
# DHCP
sed -i "s/#define DEF_LAN_ADDR.*/#define DEF_LAN_ADDR \"$NEW_LAN.1\"/" "$TRUNK_USER/shared/defaults.h"
sed -i "s/#define DEF_LAN_DHCP_BEG.*/#define DEF_LAN_DHCP_BEG \"$NEW_LAN.100\"/" "$TRUNK_USER/shared/defaults.h"
sed -i "s/#define DEF_LAN_DHCP_END.*/#define DEF_LAN_DHCP_END \"$NEW_LAN.199\"/" "$TRUNK_USER/shared/defaults.h"
# Скрипт создания дефолтных пользовательских файлов (меняем примеры SOCKS, DHCP, Hosts)
sed -i "s/192\.168\.1\.1:9050/$NEW_LAN.1:9050/g" "$TRUNK_USER/scripts/mtd_storage.sh"
sed -i "s/192\.168\.1\.10,/$NEW_LAN.10,/g" "$TRUNK_USER/scripts/mtd_storage.sh"
sed -i "s/192\.168\.1\.100/$NEW_LAN.100/g" "$TRUNK_USER/scripts/mtd_storage.sh"
# Серые HTML-подсказки в полях ввода LAN/AP
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/Advanced_LAN_Content.asp"
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/Advanced_APLAN_Content.asp"
# JS-функция сброса настроек и языковые подсказки
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/Advanced_SettingBackup_Content.asp"
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/Restarting.asp"
sed -i "s/192.168.1\./$NEW_LAN./g" "$TRUNK_USER/www/dict"/*.{dict,footer}
# Валидация данных
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/validator.js"
sed -i "s/192\.168\.1\.1/$NEW_LAN.1/g" "$WEB_DIR/general.js"

# По дефолту Wi-Fi скрытый
sed -i 's/.*"rt_closed".*/\t{ "rt_closed", "1" },/' "$TRUNK_USER/shared/defaults.c"
sed -i 's/.*"wl_closed".*/\t{ "wl_closed", "1" },/' "$TRUNK_USER/shared/defaults.c"
# Региональные настройки Wi-Fi
sed -i 's/.*"rt_country_code".*/\t{ "rt_country_code", "RU" },/' "$TRUNK_USER/shared/defaults.c"
sed -i 's/.*"wl_country_code".*/\t{ "wl_country_code", "RU" },/' "$TRUNK_USER/shared/defaults.c"

# ZAPRET
sed -i 's/.*"zapret_enable".*/\t{ "zapret_enable", "1" },/' "$TRUNK_USER/shared/defaults.c"
# DNSCRYPT
sed -i 's/.*"dnscrypt_enable".*/\t{ "dnscrypt_enable", "1" },/' "$TRUNK_USER/shared/defaults.c"
# VLMCSD
sed -i 's/.*"vlmcsd_enable".*/\t{ "vlmcsd_enable", "1" },/' "$TRUNK_USER/shared/defaults.c"
# watchdog_cpu
sed -i 's/.*"watchdog_cpu".*/\t{ "watchdog_cpu", "1" },/' "$TRUNK_USER/shared/defaults.c"
# dhcp_stop_dns_rebind
sed -i 's/.*"dhcp_stop_dns_rebind".*/\t{ "dhcp_stop_dns_rebind", "1" },/' "$TRUNK_USER/shared/defaults.c"
# dhcp_proxy_dnssec
sed -i 's/.*"dhcp_proxy_dnssec".*/\t{ "dhcp_proxy_dnssec", "1" },/' "$TRUNK_USER/shared/defaults.c"
# ez_action_long, выключение ролтона по долгому нажатию на WPS
sed -i 's/"ez_action_long", "0"/"ez_action_long", "8"/' "$TRUNK_USER/shared/defaults.c"
# DNS
sed -i 's/"redirect_all_dns", "0"/"redirect_all_dns", "1"/' "$TRUNK/user/shared/defaults.c"
sed -i 's/"dhcp_strict_order", "0"/"dhcp_strict_order", "1"/' "$TRUNK/user/shared/defaults.c"

# Сохранение настроек
sed -i 's/.*"nvram_manual".*/\t{ "nvram_manual", "1" },/' "$TRUNK_USER/shared/defaults.c"
sed -i 's/.*"rstats_enable".*/\t{ "rstats_enable", "0" },/' "$TRUNK_USER/shared/defaults.c"
sed -i 's/.*"rstats_stored".*/\t{ "rstats_stored", "0" },/' "$TRUNK_USER/shared/defaults.c"
sed -i 's/.*"stime_stored".*/\t{ "stime_stored", "1" },/' "$TRUNK_USER/shared/defaults.c"

# Комментируем дефолтные серверы в шаблоне Stubby и добавляем свои
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
    tls_auth_name: "dot.sb"' "$TRUNK_USER/stubby/stubby_proxy.sh"

# Надо облегчить прошивку, всё равно не влезает в 4мб дир300

# Оставляем шапку и основные серверы в списке dnscrypt
# sed -i -n '1p; /cisco\|cleanbrowsing\|quad9\|dnscrypt\.eu\|adguard/p' \
# "$TRUNK_USER/dnscrypt-proxy/dnscrypt-proxy-1.9.5/dnscrypt-resolvers.csv"

# Очищаем веб-интерфейс (.asp, .js, .css) от начальных пробелов/табов, пустых строк и однострочных JS-комментариев
find "$WEB_DIR" -type f \( -name "*.asp" -o -name "*.js" -o -name "*.css" \) \
    ! -name "*.min.js" ! -name "*.min.css" \
    -exec sed -i \
        -e 's/^[[:space:]]*//' \
        -e '/^[[:space:]]*\/\//d' \
        -e 's/[[:space:]]*$//' \
        -e '/^$/d' {} +

# Исключаем сборку infosvr и lanauth из общего Makefile пользовательских утилит
sed -i '/\<infosvr\>/d; /\<lanauth\>/d' "$TRUNK_USER/Makefile"
# Надо убрать упоминания о них в интерфейсе:
# Удаляем пункт 'ISP KABiNET' из выпадающего списка авторизации WAN
sed -i '/value="1".*ISP KABiNET/d' "$WEB_DIR/Advanced_WAN_Content.asp"
# Как-то так надо скрывать в asp блок с переключателем infosvr
sed -i '/<tr>/{
  $!N
  /<tr>[[:space:]]*<th><#Adm_Svc_adsc#><\/th>/ s/<tr>/<tr style="display:none;">/
  P; D
}' "$WEB_DIR/Advanced_Services_Content.asp"

# Накатываем свои оптимизированные файлы поверх исходников (без скрытых файлов, иначе: '"$OVER_TRUNK"/. "$TRUNK/".')
if [ -d "$OVER_TRUNK" ]; then
    cp -rf "$OVER_TRUNK"/* "$TRUNK/"
fi

# --- Создаем скрипт финальной очистки romfs перед упаковкой в SquashFS ---
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

# --- Предзаполнение файла маршрутов VPN для новых роутеров ---
cat << 'VPN_EOF' >> "$TRUNK/user/scripts/autostart.sh"

# Заполняем список сетей VPN при первой загрузке роутера
VPNC_LIST="/etc/storage/vpnc_remote_network.list"
if [ ! -f "/etc/storage/.vpnc_inited" ]; then
    cat << 'VPN_LIST_EOF' > "$VPNC_LIST"
# Адрес проверки IP через тоннель: https://checkip.dyndns.org/
193.122.6.168/32
# Телеграм (динамический или резервный список):
VPN_EOF

# Пытаемся скачать актуальный список сетей Telegram напрямую в файл autostart.sh
echo "Скачиваем актуальный список CIDR Telegram..."
if ! curl -sSfL "https://core.telegram.org/resources/cidr.txt" >> "$TRUNK/user/scripts/autostart.sh"; then
    echo "Ошибка скачивания. Используем резервный список."
    cat << 'FALLBACK_EOF' >> "$TRUNK/user/scripts/autostart.sh"
104.21.37.127/32
104.21.38.127/32
104.21.39.127/32
149.154.160.0/20
162.159.137.232/32
162.159.138.232/32
172.67.132.10/32
172.67.132.11/32
172.67.132.12/32
185.76.151.0/24
188.114.96.3/32
188.114.97.3/32
199.232.208.194/32
199.232.209.194/32
3.173.21.63/32
34.149.117.202/32
5.28.192.0/21
5.28.248.0/21
8.6.112.0/32
91.105.192.0/23
91.108.12.0/22
91.108.16.0/22
91.108.20.0/22
91.108.36.0/22
91.108.4.0/22
91.108.56.0/22
91.108.8.0/22
95.161.64.0/20
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
