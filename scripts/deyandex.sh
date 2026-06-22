#!/bin/bash

# DeYANDEX Interactive Setup Script
# Automatically detects connected devices and installed Yandex apps to apply privacy hardenings.

# Check for ADB
if ! command -v adb &> /dev/null; then
    echo "ADB could not be found. Please install ADB and add it to your PATH."
    exit 1
fi

# Print ASCII Art
function print_banner() {
    clear
    echo "============================================================"
    echo "   ____         __   __                _                 "
    echo "  |  _ \   ___  \ \ / / __ _  _ __    __| |  ___ __  __  "
    echo "  | | | | / _ \  \ V / / _\` || '_ \  / _\` | / _ \\ \/ /  "
    echo "  | |_| ||  __/   | | | (_| || | | || (_| ||  __/ >  <   "
    echo "  |____/  \___|   |_|  \__,_||_| |_| \__,_| \___|/_/\_\  "
    echo "============================================================"
    echo ""
}

# Select Language
print_banner
echo "Select Language / Выберите язык:"
echo "1) English"
echo "2) Русский"
read -r -p "> " lang_choice

if [ "$lang_choice" == "2" ]; then
    LANG_CODE="RU"
else
    LANG_CODE="EN"
fi

# Localization Strings
if [ "$LANG_CODE" == "RU" ]; then
    STR_NO_DEVICES="Подключенные устройства не найдены. Подключите устройство и включите отладку по USB."
    STR_SELECT_DEVICE="Выберите устройство:"
    STR_PROCESSING="Обработка приложения:"
    STR_NOT_INSTALLED="Не установлено. Пропуск."
    STR_DONE="Готово!"
    STR_YES="Да"
    STR_NO="Нет"

    Q_GLOBAL_ADID="Отключить глобальный рекламный ID (AdServices)? [Y/n]: "

    Q_BROWSER_BG="Блокировать фоновую работу Yandex Browser? [Y/n]: "
    Q_BROWSER_SENSORS="Изолировать сенсоры (камера, микрофон, локация) для Browser? [Y/n]: "
    Q_BROWSER_CLIP="Запретить Browser чтение буфера обмена? [Y/n]: "

    Q_MARKET_BG="Блокировать фоновую работу Yandex Market? [Y/n]: "
    Q_MARKET_LOC="Запретить Market точную геолокацию? [Y/n]: "

    Q_MUSIC_WAKE="Блокировать wakelocks для Yandex Music (может прерывать звук при выключенном экране)? [y/N]: "
    Q_MUSIC_SENS="Запретить Music доступ к камере и геолокации? [Y/n]: "

    Q_MAIL_SYNC="Блокировать фоновую работу/Wakelocks Yandex Mail (уведомления только при открытии)? [Y/n]: "
    Q_MAIL_CONT="Запретить Mail доступ к контактам телефона? [Y/n]: "

    Q_SEARCH_UNINSTALL="Удалить Яндекс Старт/Поиск (bloatware)? [Y/n]: "
    Q_SEARCH_BG="Если не удалять, заблокировать фоновую работу Яндекс Старт/Поиск? [Y/n]: "

    Q_NAVI_BG="Блокировать фоновую работу Yandex Navigator (может сломать фоновую навигацию)? [y/N]: "
    Q_NAVI_SENS="Запретить Navigator доступ к камере (AR) и микрофону (Алиса)? [Y/n]: "
    Q_NAVI_WAKE="Запретить Navigator будить устройство (устраняет зависший GPS-значок)? [Y/n]: "

    Q_TRANS_BG="Блокировать фоновую работу Yandex Translate (отключает фоновую телеметрию)? [Y/n]: "
    Q_TRANS_CLIP="Запретить Translate авточтение буфера обмена? [Y/n]: "

    Q_DISK_BG="Блокировать фоновую работу Yandex Disk? [Y/n]: "
    Q_DISK_SENS="Изолировать Disk (камера, локация, доступ к медиа)? [Y/n]: "

    Q_LAVKA_BG="Блокировать фоновую работу Yandex Lavka? [Y/n]: "
    Q_LAVKA_SENS="Изолировать Lavka (локация, контакты, запись экрана)? [Y/n]: "

    Q_KEYBOARD_SENS="Изолировать Клавиатуру (микрофон, контакты, словарь)? [Y/n]: "
    Q_KEYBOARD_NET="Заблокировать Клавиатуре доступ в интернет (NetPolicy)? [Y/n]: "
else
    STR_NO_DEVICES="No connected devices found. Please connect a device and enable USB debugging."
    STR_SELECT_DEVICE="Select a device:"
    STR_PROCESSING="Processing app:"
    STR_NOT_INSTALLED="Not installed. Skipping."
    STR_DONE="Done!"
    STR_YES="Yes"
    STR_NO="No"

    Q_GLOBAL_ADID="Disable global Advertising ID (AdServices) stack? [Y/n]: "

    Q_BROWSER_BG="Block background execution for Yandex Browser? [Y/n]: "
    Q_BROWSER_SENSORS="Isolate sensors (camera, mic, location) for Browser? [Y/n]: "
    Q_BROWSER_CLIP="Prevent Browser from reading clipboard? [Y/n]: "

    Q_MARKET_BG="Block background execution for Yandex Market? [Y/n]: "
    Q_MARKET_LOC="Prevent Market from accessing precise location? [Y/n]: "

    Q_MUSIC_WAKE="Block wakelocks for Yandex Music (may pause playback on screen off)? [y/N]: "
    Q_MUSIC_SENS="Prevent Music from accessing camera and location? [Y/n]: "

    Q_MAIL_SYNC="Block background sync/wakelocks for Yandex Mail (notifications only on open)? [Y/n]: "
    Q_MAIL_CONT="Prevent Mail from accessing phone contacts? [Y/n]: "

    Q_SEARCH_UNINSTALL="Uninstall Yandex Start/Searchplugin (bloatware)? [Y/n]: "
    Q_SEARCH_BG="If not uninstalled, block background execution for Yandex Start/Searchplugin? [Y/n]: "

    Q_NAVI_BG="Block background execution for Yandex Navigator (may break background routing)? [y/N]: "
    Q_NAVI_SENS="Prevent Navigator from accessing camera (AR) and mic (Alice)? [Y/n]: "
    Q_NAVI_WAKE="Prevent Navigator from waking device (fixes sticky GPS icon)? [Y/n]: "

    Q_TRANS_BG="Block background execution for Yandex Translate (disables telemetry)? [Y/n]: "
    Q_TRANS_CLIP="Prevent Translate from automatically reading clipboard? [Y/n]: "

    Q_DISK_BG="Block background execution for Yandex Disk? [Y/n]: "
    Q_DISK_SENS="Isolate Disk (camera, location, media access)? [Y/n]: "

    Q_LAVKA_BG="Block background execution for Yandex Lavka? [Y/n]: "
    Q_LAVKA_SENS="Isolate Lavka (location, contacts, screen recording)? [Y/n]: "

    Q_KEYBOARD_SENS="Isolate Yandex Keyboard (mic, contacts, dictionary)? [Y/n]: "
    Q_KEYBOARD_NET="Block Internet access for Yandex Keyboard (NetPolicy)? [Y/n]: "
fi

# Device Selection
print_banner
mapfile -t devices < <(adb devices | grep -v "List of devices attached" | grep "device" | awk '{print $1}')

if [ ${#devices[@]} -eq 0 ]; then
    echo "$STR_NO_DEVICES"
    exit 1
fi

if [ ${#devices[@]} -eq 1 ]; then
    SELECTED_DEVICE=${devices[0]}
else
    echo "$STR_SELECT_DEVICE"
    for i in "${!devices[@]}"; do
        echo "$(($i+1))) ${devices[$i]}"
    done
    read -r -p "> " dev_choice
    if [[ ! "$dev_choice" =~ ^[1-9][0-9]*$ ]] || [ "${#dev_choice}" -gt 5 ] || [ "$dev_choice" -lt 1 ] || [ "$dev_choice" -gt "${#devices[@]}" ]; then
        echo "Invalid selection / Неверный выбор."
        exit 1
    fi
    SELECTED_DEVICE=${devices[$(($dev_choice-1))]}
fi

echo "Using device: $SELECTED_DEVICE"
echo ""

LOG_FILE="deyandex.log"
rm -f "$LOG_FILE" 2>/dev/null
if ! (set -C; echo -n > "$LOG_FILE") 2>/dev/null; then
    echo "Security Error: Log file could not be created securely." >&2
    exit 1
fi
chmod 600 "$LOG_FILE"
exec > >(tee "$LOG_FILE") 2>&1

echo "Logs will be saved to $LOG_FILE"
echo ""

function adbs() {
    adb -s "$SELECTED_DEVICE" shell "$@"
}

function get_uid() {
    local pkg="$1"
    local raw_uids
    local valid_uids=0
    raw_uids=$(adbs dumpsys package "$pkg" | tr -d '\r' | grep userId= | awk -F= '{print $2}' | awk '{print $1}')

    while IFS= read -r uid; do
        [ -z "$uid" ] && continue
        if [[ "$uid" =~ ^[0-9]+$ ]]; then
            echo "$uid"
            valid_uids=$((valid_uids + 1))
        else
            printf "\033[1;31m[!] SECURITY WARNING: Invalid UID format detected: '%s'\033[0m\n" "$uid" >&2
        fi
    done <<< "$raw_uids"

    if [ "$valid_uids" -eq 0 ]; then
         printf "\033[1;31m[!] SECURITY WARNING: No valid UIDs found for %s. Policies may be bypassed!\033[0m\n" "$pkg" >&2
    fi
}

function apply_common_hardening() {
    local pkg="$1"
    # Force restricted standby bucket
    adbs am set-standby-bucket "$pkg" restricted
    
    # NetPolicy: restrict background data usage
    local uids=$(get_uid "$pkg")
    if [ ! -z "$uids" ]; then
        while IFS= read -r u; do
            adbs cmd netpolicy set restrict-background true "$u"
        done <<< "$uids"
    fi
}

function ask() {
    local prompt="$1"
    local default="$2"
    local desc="$3"
    
    printf "\033[1;34m[?]\033[0m %s\n" "$prompt"
    if [ ! -z "$desc" ]; then
        printf "\033[0;90m    i: %s\033[0m\n" "$desc"
    fi
    
    read -r -p "> " answer
    if [ -z "$answer" ]; then
        answer="$default"
    fi
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

function check_installed() {
    local pkg="$1"
    adbs pm list packages --user 0 | tr -d '\r' | grep -F -x -q "package:${pkg}"
}

# Global Hardening
printf "\n\033[1;33m--- GLOBAL HARDENING ---\033[0m\n"
if ask "$Q_GLOBAL_ADID" "y" "Disables Android's system-level Advertising ID stack (AdServices). Most effective against cross-app tracking."; then
    adbs cmd device_config put adservices global_kill_switch true
    adbs cmd device_config put adservices fledge_is_measurement_enabled false
    adbs cmd device_config put adservices fledge_is_custom_audience_enabled false
    adbs cmd device_config put adservices fledge_is_topics_enabled false
    printf "\033[1;32m[+]\033[0m Global AdServices disabled.\n"
fi

# --- App Processing ---

# Browser
pkg="com.yandex.browser"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "$Q_BROWSER_BG" "y" "Stops background sync, Zen feeds, and battery drain. App will work only when open."; then
        adbs cmd appops set "$pkg" RUN_IN_BACKGROUND ignore
        adbs cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore
        adbs cmd appops set "$pkg" WAKE_LOCK ignore
        apply_common_hardening "$pkg"
    fi
    if ask "$Q_BROWSER_SENSORS" "y" "Prevents access to Camera, Mic, GPS, Calendar, and Phone IDs (IMEI/IMSI)."; then
        adbs cmd appops set "$pkg" FINE_LOCATION ignore
        adbs cmd appops set "$pkg" CAMERA ignore
        adbs cmd appops set "$pkg" RECORD_AUDIO ignore
        adbs cmd appops set "$pkg" READ_CALENDAR ignore
        adbs cmd appops set "$pkg" READ_PHONE_STATE ignore
        adbs cmd appops set "$pkg" READ_EXTERNAL_STORAGE ignore
        adbs cmd appops set "$pkg" WRITE_EXTERNAL_STORAGE ignore
        adbs cmd appops set "$pkg" ACCESS_MEDIA_LOCATION ignore
        adbs cmd appops set "$pkg" SYSTEM_ALERT_WINDOW ignore
    fi
    if ask "$Q_BROWSER_CLIP" "y" "Highly recommended. Prevents the app from reading your passwords/codes from clipboard."; then
        adbs cmd appops set "$pkg" READ_CLIPBOARD ignore
    fi
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

# Market (Beru)
pkg="ru.beru.android"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "$Q_MARKET_BG" "y" "Stops background tracking of your shopping habits and price monitoring."; then
        adbs cmd appops set "$pkg" RUN_IN_BACKGROUND ignore
        adbs cmd appops set "$pkg" WAKE_LOCK ignore
        apply_common_hardening "$pkg"
    fi
    if ask "$Q_MARKET_LOC" "y" "Restricts access to Location, Contacts, and Bluetooth scanning."; then
        adbs cmd appops set "$pkg" FINE_LOCATION ignore
        adbs cmd appops set "$pkg" CAMERA ignore
        adbs cmd appops set "$pkg" RECORD_AUDIO ignore
        adbs cmd appops set "$pkg" READ_CONTACTS ignore
        adbs cmd appops set "$pkg" BLUETOOTH_SCAN ignore
        adbs cmd appops set "$pkg" PROJECT_MEDIA ignore
    fi
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

# Music
pkg="ru.yandex.music"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "$Q_MUSIC_WAKE" "n" "RISK: Music may stop when screen turns off. Enable ONLY if you experience high idle drain."; then
        adbs cmd appops set "$pkg" WAKE_LOCK ignore
        apply_common_hardening "$pkg"
    fi
    if ask "$Q_MUSIC_SENS" "y" "Blocks Mic, Camera and Location. Essential music functions will remain active."; then
        adbs cmd appops set "$pkg" FINE_LOCATION ignore
        adbs cmd appops set "$pkg" CAMERA ignore
        adbs cmd appops set "$pkg" RECORD_AUDIO ignore
    fi
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

# Mail
pkg="ru.yandex.mail"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "$Q_MAIL_SYNC" "y" "RISK: You will not get Push notifications. Mails sync only when you open the app."; then
        adbs cmd appops set "$pkg" RUN_IN_BACKGROUND ignore
        adbs cmd appops set "$pkg" WAKE_LOCK ignore
        apply_common_hardening "$pkg"
    fi
    if ask "$Q_MAIL_CONT" "y" "Prevents the app from uploading your contact book to Yandex servers."; then
        adbs cmd appops set "$pkg" READ_CONTACTS ignore
    fi
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

# Searchplugin
pkg="ru.yandex.searchplugin"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "$Q_SEARCH_UNINSTALL" "y" "Recommended. This is bloatware. Core functions are available in the Browser."; then
        adbs pm uninstall -k --user 0 "$pkg"
    else
        if ask "$Q_SEARCH_BG" "y" "Isolates the search widget and Alice from background data collection."; then
            adbs cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND ignore
            adbs cmd appops set "$pkg" WAKE_LOCK ignore
            adbs cmd appops set "$pkg" FINE_LOCATION ignore
            apply_common_hardening "$pkg"
        fi
    fi
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

# Taxi / Go
pkg="ru.yandex.taxi"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "Block background execution for Yandex Go/Taxi? [y/N]: " "n" "RISK: May affect real-time ride tracking notifications."; then
        adbs cmd appops set "$pkg" RUN_IN_BACKGROUND ignore
        adbs cmd appops set "$pkg" WAKE_LOCK ignore
        apply_common_hardening "$pkg"
    fi
    adbs cmd appops set "$pkg" READ_PHONE_STATE ignore
    adbs cmd appops set "$pkg" CALL_PHONE ignore
    adbs cmd appops set "$pkg" GET_ACCOUNTS ignore
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

# Maps
pkg="ru.yandex.yandexmaps"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "Block background execution for Yandex Maps? [y/N]: " "n" "RISK: Background navigation guidance may stop."; then
        adbs cmd appops set "$pkg" RUN_IN_BACKGROUND ignore
        adbs cmd appops set "$pkg" WAKE_LOCK ignore
        apply_common_hardening "$pkg"
    fi
    adbs cmd appops set "$pkg" ACTIVITY_RECOGNITION ignore
    adbs cmd appops set "$pkg" READ_PHONE_STATE ignore
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

# Navigator
pkg="ru.yandex.yandexnavi"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "$Q_NAVI_BG" "n" "RISK: Will break navigation if you switch to another app."; then
        adbs cmd appops set "$pkg" RUN_IN_BACKGROUND ignore
        apply_common_hardening "$pkg"
    fi
    if ask "$Q_NAVI_SENS" "y" "Blocks Alice and AR features while keeping GPS navigation."; then
        adbs cmd appops set "$pkg" CAMERA ignore
        adbs cmd appops set "$pkg" RECORD_AUDIO ignore
    fi
    if ask "$Q_NAVI_WAKE" "y" "Fixes the 'sticky GPS icon' and prevents idle battery drain."; then
        adbs cmd appops set "$pkg" WAKE_LOCK ignore
    fi
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

# Disk
pkg="ru.yandex.disk"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "$Q_DISK_BG" "y" "RISK: Automatic photo upload will only work when app is open."; then
        adbs cmd appops set "$pkg" RUN_IN_BACKGROUND ignore
        adbs cmd appops set "$pkg" WAKE_LOCK ignore
        apply_common_hardening "$pkg"
    fi
    if ask "$Q_DISK_SENS" "y" "Prevents the app from scanning all your media files and metadata in background."; then
        adbs cmd appops set "$pkg" FINE_LOCATION ignore
        adbs cmd appops set "$pkg" CAMERA ignore
        adbs cmd appops set "$pkg" READ_EXTERNAL_STORAGE ignore
        adbs cmd appops set "$pkg" WRITE_EXTERNAL_STORAGE ignore
        adbs cmd appops set "$pkg" ACCESS_MEDIA_LOCATION ignore
    fi
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

# Lavka
pkg="com.yandex.lavka"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "$Q_LAVKA_BG" "y" "Prevents background tracking of delivery status and your location."; then
        adbs cmd appops set "$pkg" RUN_IN_BACKGROUND ignore
        adbs cmd appops set "$pkg" WAKE_LOCK ignore
        apply_common_hardening "$pkg"
    fi
    if ask "$Q_LAVKA_SENS" "y" "Blocks access to Contacts, precise Location and Screen Recording."; then
        adbs cmd appops set "$pkg" FINE_LOCATION ignore
        adbs cmd appops set "$pkg" READ_CONTACTS ignore
        adbs cmd appops set "$pkg" PROJECT_MEDIA ignore
    fi
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

# Keyboard
pkg="ru.yandex.androidkeyboard"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "$Q_KEYBOARD_SENS" "y" "Blocks Microphone (voice input), Contacts and user Dictionary access."; then
        adbs cmd appops set "$pkg" RECORD_AUDIO ignore
        adbs cmd appops set "$pkg" READ_CONTACTS ignore
    fi
    if ask "$Q_KEYBOARD_NET" "y" "EXPERIMENTAL: Completely cuts internet for the keyboard. May break voice input or updates."; then
        uids=$(get_uid "$pkg")
        if [ ! -z "$uids" ]; then
            while IFS= read -r u; do
                adbs cmd netpolicy set restrict-background true "$u"
                # Hard block data usage if supported
                adbs cmd netpolicy set-statistics --uid "$u" --metered-network-restricted true
            done <<< "$uids"
        fi
    fi
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

# Translate
pkg="ru.yandex.translate"
printf "\n\033[1;36m[ APP ] %s\033[0m\n" "$pkg"
if check_installed "$pkg"; then
    if ask "$Q_TRANS_BG" "y" "Disables idle telemetry. Translator works only when open."; then
        adbs cmd appops set "$pkg" RUN_IN_BACKGROUND ignore
        adbs cmd appops set "$pkg" WAKE_LOCK ignore
        apply_common_hardening "$pkg"
    fi
    if ask "$Q_TRANS_CLIP" "y" "Prevents background clipboard sniffing. Recommended."; then
        adbs cmd appops set "$pkg" READ_CLIPBOARD ignore
        adbs cmd appops set "$pkg" SYSTEM_ALERT_WINDOW ignore
        adbs cmd appops set "$pkg" BLUETOOTH_SCAN ignore
        adbs cmd appops set "$pkg" PROJECT_MEDIA ignore
    fi
    adbs am force-stop "$pkg"
else
    printf "\033[0;90m%s\033[0m\n" "$STR_NOT_INSTALLED"
fi

echo "-----------------------------------"
echo "$STR_DONE"
