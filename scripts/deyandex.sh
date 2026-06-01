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
    echo "  ____   __   __      _    _   _ ____  _______  __"
    echo " |  _ \  \ \ / /_ _  | \ | | |  _ \| ____\ \/ /"
    echo " | | | |  \ V / _  | |  \| | | | | |  _|  \  /"
    echo " | |_| |   | | (_| | | |\  | | |_| | |___ /  \\"
    echo " |____/    |_|\__,_| |_| \_| |____/|_____/_/\_\\"
    echo "============================================================"
    echo ""
}

# Select Language
print_banner
echo "Select Language / Выберите язык:"
echo "1) English"
echo "2) Русский"
read -p "> " lang_choice

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
else
    STR_NO_DEVICES="No connected devices found. Please connect a device and enable USB debugging."
    STR_SELECT_DEVICE="Select a device:"
    STR_PROCESSING="Processing app:"
    STR_NOT_INSTALLED="Not installed. Skipping."
    STR_DONE="Done!"
    STR_YES="Yes"
    STR_NO="No"

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
fi

# Device Selection
print_banner
devices=($(adb devices | grep -v "List of devices attached" | grep "device" | awk '{print $1}'))

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
    read -p "> " dev_choice
    SELECTED_DEVICE=${devices[$(($dev_choice-1))]}
fi

echo "Using device: $SELECTED_DEVICE"
echo ""

function adbs() {
    adb -s "$SELECTED_DEVICE" shell "$@"
}

function ask() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt" answer
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
    adbs pm list packages | grep -q "$pkg"
}

# --- App Processing ---

# Browser
pkg="com.yandex.browser"
echo "-----------------------------------"
echo "$STR_PROCESSING $pkg"
if check_installed "$pkg"; then
    if ask "$Q_BROWSER_BG" "y"; then
        adbs cmd appops set $pkg RUN_IN_BACKGROUND ignore
        adbs cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore
        adbs cmd appops set $pkg WAKE_LOCK ignore
    fi
    if ask "$Q_BROWSER_SENSORS" "y"; then
        adbs cmd appops set $pkg ACCESS_FINE_LOCATION ignore
        adbs cmd appops set $pkg CAMERA ignore
        adbs cmd appops set $pkg RECORD_AUDIO ignore
    fi
    if ask "$Q_BROWSER_CLIP" "y"; then
        adbs cmd appops set $pkg READ_CLIPBOARD ignore
    fi
else
    echo "$STR_NOT_INSTALLED"
fi

# Market
pkg="ru.yandex.market"
echo "-----------------------------------"
echo "$STR_PROCESSING $pkg"
if check_installed "$pkg"; then
    if ask "$Q_MARKET_BG" "y"; then
        adbs cmd appops set $pkg RUN_IN_BACKGROUND ignore
        adbs cmd appops set $pkg WAKE_LOCK ignore
    fi
    if ask "$Q_MARKET_LOC" "y"; then
        adbs cmd appops set $pkg ACCESS_FINE_LOCATION ignore
    fi
else
    echo "$STR_NOT_INSTALLED"
fi

# Music
pkg="ru.yandex.music"
echo "-----------------------------------"
echo "$STR_PROCESSING $pkg"
if check_installed "$pkg"; then
    if ask "$Q_MUSIC_WAKE" "n"; then
        adbs cmd appops set $pkg WAKE_LOCK ignore
    fi
    if ask "$Q_MUSIC_SENS" "y"; then
        adbs cmd appops set $pkg ACCESS_FINE_LOCATION ignore
        adbs cmd appops set $pkg CAMERA ignore
    fi
else
    echo "$STR_NOT_INSTALLED"
fi

# Mail
pkg="ru.yandex.mail"
echo "-----------------------------------"
echo "$STR_PROCESSING $pkg"
if check_installed "$pkg"; then
    if ask "$Q_MAIL_SYNC" "y"; then
        adbs cmd appops set $pkg RUN_IN_BACKGROUND ignore
        adbs cmd appops set $pkg WAKE_LOCK ignore
    fi
    if ask "$Q_MAIL_CONT" "y"; then
        adbs cmd appops set $pkg READ_CONTACTS ignore
    fi
else
    echo "$STR_NOT_INSTALLED"
fi

# Searchplugin
pkg="ru.yandex.searchplugin"
echo "-----------------------------------"
echo "$STR_PROCESSING $pkg"
if check_installed "$pkg"; then
    if ask "$Q_SEARCH_UNINSTALL" "y"; then
        adbs pm uninstall -k --user 0 $pkg
    else
        if ask "$Q_SEARCH_BG" "y"; then
            adbs cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore
            adbs cmd appops set $pkg WAKE_LOCK ignore
            adbs cmd appops set $pkg ACCESS_FINE_LOCATION ignore
        fi
    fi
else
    echo "$STR_NOT_INSTALLED"
fi

# Navigator
pkg="ru.yandex.yandexnavi"
echo "-----------------------------------"
echo "$STR_PROCESSING $pkg"
if check_installed "$pkg"; then
    if ask "$Q_NAVI_BG" "n"; then
        adbs cmd appops set $pkg RUN_IN_BACKGROUND ignore
    fi
    if ask "$Q_NAVI_SENS" "y"; then
        adbs cmd appops set $pkg CAMERA ignore
        adbs cmd appops set $pkg RECORD_AUDIO ignore
    fi
    if ask "$Q_NAVI_WAKE" "y"; then
        adbs cmd appops set $pkg WAKE_LOCK ignore
    fi
else
    echo "$STR_NOT_INSTALLED"
fi

# Translate
pkg="ru.yandex.translate"
echo "-----------------------------------"
echo "$STR_PROCESSING $pkg"
if check_installed "$pkg"; then
    if ask "$Q_TRANS_BG" "y"; then
        adbs cmd appops set $pkg RUN_IN_BACKGROUND ignore
        adbs cmd appops set $pkg WAKE_LOCK ignore
    fi
    if ask "$Q_TRANS_CLIP" "y"; then
        adbs cmd appops set $pkg READ_CLIPBOARD ignore
    fi
else
    echo "$STR_NOT_INSTALLED"
fi

echo "-----------------------------------"
echo "$STR_DONE"
