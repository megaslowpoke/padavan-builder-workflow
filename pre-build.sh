#!/bin/bash
# Переходим в каталог со скачанными исходниками
cd padavan-ng || exit 2
# Обновляем корневые сертификаты с помощью родного скрипта
(
    cd trunk/libs/libssl || exit 2
    chmod +x ca-certificates_update.sh
    ./ca-certificates_update.sh || exit 2
)
# --- Базовые настройки ---
# Часовой пояс (MSK-3)
#москва
#sed -i 's/.*"time_zone".*/\t{ "time_zone", "UTC-3" },/' trunk/user/shared/defaults.c
#минск
#sed -i 's/.*"time_zone".*/\t{ "time_zone", "UCT-3_1" },/' trunk/user/shared/defaults.c
#багдад
#sed -i 's/.*"time_zone".*/\t{ "time_zone", "IST-3IDT" },/' trunk/user/shared/defaults.c
#найроби
sed -i 's/.*"time_zone".*/\t{ "time_zone", "UCT-3_2" },/' trunk/user/shared/defaults.c

# NTP-серверы
#sed -i 's/.*"ntp_server0".*/\t{ "ntp_server0", "time100.stupi.se" },/' trunk/user/shared/defaults.c
#sed -i 's/.*"ntp_server1".*/\t{ "ntp_server1", "ntp1.vniiftri.ru" },/' trunk/user/shared/defaults.c
#sed -i 's/.*"ntp_server2".*/\t{ "ntp_server2", "time.esa.int" },/' trunk/user/shared/defaults.c
#sed -i 's/.*"ntp_server3".*/\t{ "ntp_server3", "ojab.ru" },/' trunk/user/shared/defaults.c
sed -i 's/#define DEF_NTP_SERVER0.*/#define DEF_NTP_SERVER0 "ntp.ix.ru"/' trunk/user/shared/defaults.h
sed -i 's/#define DEF_NTP_SERVER1.*/#define DEF_NTP_SERVER1 "ntp.msk-ix.ru"/' trunk/user/shared/defaults.h
sed -i 's/#define DEF_NTP_SERVER2.*/#define DEF_NTP_SERVER2 "ru.pool.ntp.org"/' trunk/user/shared/defaults.h
sed -i 's/#define DEF_NTP_SERVER3.*/#define DEF_NTP_SERVER3 "time.cloudflare.com"/' trunk/user/shared/defaults.h

sed -i 's|server=/ntp.org/time.cloudflare.com/time.google.com/time.in.ua/1.1.1.1|server=/ntp.ix.ru/ntp.msk-ix.ru/ru.pool.ntp.org/time.cloudflare.com/time100.stupi.se/ntp1.vniiftri.ru/ojab.ru/time.esa.int/185.228.168.9|' trunk/user/scripts/mtd_storage.sh

# --- Авторизация и доступ ---
# Язык веб-интерфейса
#sed -i 's/.*"web_ui_lang".*/\t{ "web_ui_lang", "RU" },/' trunk/user/shared/defaults.c

# SSH по умолчанию
#sed -i 's/.*"sshd_enable".*/\t{ "sshd_enable", "1" },/' trunk/user/shared/defaults.c

# Логин и пароль от веб-интерфейса и SSH
sed -i 's/.*"http_username".*/\t{ "http_username", "admin" },/' trunk/user/shared/defaults.c
sed -i 's/.*"http_passwd".*/\t{ "http_passwd", "" },/' trunk/user/shared/defaults.c

# --- Сеть и Wi-Fi ---
sed -i 's/#define DEF_LAN_DHCP_BEG.*/#define DEF_LAN_DHCP_BEG "192.168.1.100"/' trunk/user/shared/defaults.h
sed -i 's/#define DEF_LAN_DHCP_END.*/#define DEF_LAN_DHCP_END "192.168.1.199"/' trunk/user/shared/defaults.h
# Wi-Fi
sed -i 's/.*"rt_closed".*/\t{ "rt_closed", "1" },/' trunk/user/shared/defaults.c
sed -i 's/.*"wl_closed".*/\t{ "wl_closed", "1" },/' trunk/user/shared/defaults.c
# Региональные настройки Wi-Fi
sed -i 's/.*"rt_country_code".*/\t{ "rt_country_code", "RU" },/' trunk/user/shared/defaults.c
sed -i 's/.*"wl_country_code".*/\t{ "wl_country_code", "RU" },/' trunk/user/shared/defaults.c

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
    tls_auth_name: "dot.sb"' trunk/user/stubby/stubby_proxy.sh

# надо облегчить прошивку, всё равно не влезает
# Удаляем неиспользуемые иконки и скрипт USB-дисков
rm -rf padavan-ng/trunk/user/www/n56u_ribbon_fixed/bootstrap/img/icons/aidisk
> padavan-ng/trunk/user/www/n56u_ribbon_fixed/disk_functions.js

# Убираем начальные пробелы/табы и пустые строки в .js, .css и .asp
find padavan-ng/trunk/user/www/n56u_ribbon_fixed/ -type f \( -name "*.js" -o -name "*.css" -o -name "*.asp" \) \
  -exec sed -i -e 's/^[ \t]*//' -e '/^$/d' {} +

# Заменяем тяжелую иконку Windows LLTD и дубль фавиконки на пустые файлы
> padavan-ng/trunk/user/www/n56u_ribbon_fixed/images/favicon.ico
find padavan-ng/trunk/ -name "icon.ico" -exec truncate -s 0 {} +
