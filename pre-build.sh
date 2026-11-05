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
# --- Базовые настройки ---
# Часовой пояс (MSK-3)
#москва
#sed -i 's/.*"time_zone".*/\t{ "time_zone", "UTC-3" },/' $TRUNK_USER/shared/defaults.c
#минск
#sed -i 's/.*"time_zone".*/\t{ "time_zone", "UCT-3_1" },/' $TRUNK_USER/shared/defaults.c
#багдад
#sed -i 's/.*"time_zone".*/\t{ "time_zone", "IST-3IDT" },/' $TRUNK_USER/shared/defaults.c
#найроби
sed -i 's/.*"time_zone".*/\t{ "time_zone", "UCT-3_2" },/' $TRUNK_USER/shared/defaults.c

# NTP-серверы
#sed -i 's/.*"ntp_server0".*/\t{ "ntp_server0", "time100.stupi.se" },/' $TRUNK_USER/shared/defaults.c
#sed -i 's/.*"ntp_server1".*/\t{ "ntp_server1", "ntp1.vniiftri.ru" },/' $TRUNK_USER/shared/defaults.c
#sed -i 's/.*"ntp_server2".*/\t{ "ntp_server2", "time.esa.int" },/' $TRUNK_USER/shared/defaults.c
#sed -i 's/.*"ntp_server3".*/\t{ "ntp_server3", "ojab.ru" },/' $TRUNK_USER/shared/defaults.c
sed -i 's/#define DEF_NTP_SERVER0.*/#define DEF_NTP_SERVER0 "ntp.ix.ru"/' $TRUNK_USER/shared/defaults.h
sed -i 's/#define DEF_NTP_SERVER1.*/#define DEF_NTP_SERVER1 "ntp.msk-ix.ru"/' $TRUNK_USER/shared/defaults.h
sed -i 's/#define DEF_NTP_SERVER2.*/#define DEF_NTP_SERVER2 "ru.pool.ntp.org"/' $TRUNK_USER/shared/defaults.h
sed -i 's/#define DEF_NTP_SERVER3.*/#define DEF_NTP_SERVER3 "time.cloudflare.com"/' $TRUNK_USER/shared/defaults.h

sed -i 's|server=/ntp.org/time.cloudflare.com/time.google.com/time.in.ua/1.1.1.1|server=/ntp.ix.ru/ntp.msk-ix.ru/ru.pool.ntp.org/time.cloudflare.com/time100.stupi.se/ntp1.vniiftri.ru/ojab.ru/time.esa.int/185.228.168.9|' $TRUNK_USER/scripts/mtd_storage.sh

# --- Авторизация и доступ ---
# Язык веб-интерфейса
#sed -i 's/.*"web_ui_lang".*/\t{ "web_ui_lang", "RU" },/' $TRUNK_USER/shared/defaults.c

# SSH по умолчанию
#sed -i 's/.*"sshd_enable".*/\t{ "sshd_enable", "1" },/' $TRUNK_USER/shared/defaults.c

# Логин и пароль от веб-интерфейса и SSH
sed -i 's/.*"http_username".*/\t{ "http_username", "admin" },/' $TRUNK_USER/shared/defaults.c
sed -i 's/.*"http_passwd".*/\t{ "http_passwd", "" },/' $TRUNK_USER/shared/defaults.c

# --- Сеть и Wi-Fi ---
sed -i 's/#define DEF_LAN_DHCP_BEG.*/#define DEF_LAN_DHCP_BEG "192.168.1.100"/' $TRUNK_USER/shared/defaults.h
sed -i 's/#define DEF_LAN_DHCP_END.*/#define DEF_LAN_DHCP_END "192.168.1.199"/' $TRUNK_USER/shared/defaults.h
# Wi-Fi
sed -i 's/.*"rt_closed".*/\t{ "rt_closed", "1" },/' $TRUNK_USER/shared/defaults.c
sed -i 's/.*"wl_closed".*/\t{ "wl_closed", "1" },/' $TRUNK_USER/shared/defaults.c
# Региональные настройки Wi-Fi
sed -i 's/.*"rt_country_code".*/\t{ "rt_country_code", "RU" },/' $TRUNK_USER/shared/defaults.c
sed -i 's/.*"wl_country_code".*/\t{ "wl_country_code", "RU" },/' $TRUNK_USER/shared/defaults.c

# настройки dns
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
    tls_auth_name: "dot.sb"' $TRUNK_USER/stubby/stubby_proxy.sh

# надо облегчить прошивку, всё равно не влезает в дир300

# Оставляем шапку и основные серверы в списке dnscrypt
#sed -i -n '1p; /cisco\|cleanbrowsing\|quad9\|dnscrypt\.eu\|adguard/p' \
#  $TRUNK_USER/dnscrypt-proxy/dnscrypt-proxy-1.9.5/dnscrypt-resolvers.csv

# Очищаем веб-интерфейс (.asp, .js, .css) от начальных пробелов/табов,
# пустых строк и однострочных JS-комментариев
find "$WEB_DIR" -type f \( -name "*.asp" -o -name "*.js" -o -name "*.css" \) \
    ! -name "*.min.js" ! -name "*.min.css" \
    -exec sed -i \
        -e 's/^[[:space:]]*//' \
        -e '/^[[:space:]]*\/\//d' \
        -e 's/[[:space:]]*$//' \
        -e '/^$/d' {} +

# Исключаем сборку infosvr и lanauth из общего Makefile пользовательских утилит
sed -i '/\<infosvr\>/d; /\<lanauth\>/d' "$TRUNK_USER/Makefile"
# надо убрать упоминания о них в интерфейсе:
# Удаляем пункт 'ISP KABiNET' из выпадающего списка авторизации WAN
sed -i '/value="1".*ISP KABiNET/d' "$WEB_DIR/Advanced_WAN_Content.asp"
# как-то так надо скрывать в asp блок с переключателем infosvr
sed -i '/<tr>/{
  $!N
  /<tr>[[:space:]]*<th><#Adm_Svc_adsc#><\/th>/ s/<tr>/<tr style="display:none;">/
  P; D
}' "$WEB_DIR/Advanced_Services_Content.asp"

# Накатываем свои оптимизированные файлы поверх исходников
if [ -d "$OVER_TRUNK" ]; then
    cp -rf $OVER_TRUNK/* "$TRUNK/"
fi

# Создаем скрипт финальной зачистки romfs перед упаковкой в SquashFS
# 1. На всякий случай убираем 'exit 0' в конце strip-romfs.sh, если он там есть
sed -i '/^[[:space:]]*exit[[:space:]]*0/d' "$TRUNK/tools/strip-romfs.sh"

# 2. Дописываем жесткую зачистку прямо в конец strip-romfs.sh
cat << 'EOF' >> "$TRUNK/tools/strip-romfs.sh"

echo "=== [CUSTOM CLEAN] Cleaning extra files in $ROMFSDIR ==="
rm -rfv "$ROMFSDIR/usr/share/terminfo/a" \
        "$ROMFSDIR/usr/share/terminfo/d" \
        "$ROMFSDIR/usr/share/terminfo/s" \
        "$ROMFSDIR/usr/share/terminfo/v/vt220" \
        "$ROMFSDIR/usr/share/terminfo/x/xterm-color" \
        "$ROMFSDIR/usr/share/terminfo/x/xterm-r6" \
        "$ROMFSDIR/usr/share/terminfo/x/xterm-xfree86" \
        "$ROMFSDIR/usr/share/terminfo/screen" \
        "$ROMFSDIR/usr/share/terminfo/vt200" \
        "$ROMFSDIR/usr/share/terminfo/xterm-color" \
        "$ROMFSDIR/etc_ro/icon.ico" \
        "$ROMFSDIR/etc_ro/icon.large.ico" \
        "$ROMFSDIR/www/images/favicon.ico" \
        "$ROMFSDIR/www/disk_functions.js" \
        "$ROMFSDIR/www/qrcode.min.js" \
        "$ROMFSDIR/www/bootstrap/img/icons/aidisk"
EOF
