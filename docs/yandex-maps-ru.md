# DeYandex: гайд по Yandex Maps

Пакет: `ru.yandex.yandexmaps`

Тестовое устройство, на котором проверялись команды:

- устройство: Samsung SM-S901E;
- Android: 16 / SDK 36;
- версия Yandex Maps: `28.6.5`;
- version code: `739172530`;
- UID приложения на тестовом устройстве: `10368`.

На вашем устройстве UID будет другим. Перед командами для `netpolicy` всегда
получайте UID локально.

## Вступление

Yandex Maps - это не только отображение карты. В проверенной версии есть
интеграция аккаунта, push-сообщения, рекламные и attribution API, Android Auto,
foreground services, файловые/media providers и analytics SDK. Часть этого
может быть связана с видимыми функциями, но многое не нужно для базовых задач:
открыть карту, найти место, построить маршрут вручную.

Этот гайд показывает, что можно убрать или ограничить обычным ADB на Android
14-16 без root, Magisk, Shizuku и перепаковки APK. Гайд не обещает полной
деанонимизации или полного удаления всей телеметрии: у ADB-only подхода есть
четкие технические границы.

## Цель

Цель - оставить Yandex Maps пригодными для использования как карты, но убрать
как можно больше доступа, который не нужен для основной функции приложения.

Для базового использования карт обычно нужны foreground-сеть и, если вам нужна
навигация по текущему местоположению, foreground-геолокация. Все остальное
лучше считать опциональным, пока не доказано обратное: камера, микрофон,
контакты, медиа, Bluetooth, activity recognition, background location,
advertising ID, доступ к аккаунтам, фоновые задачи, exact alarms, чтение
буфера обмена, автозапуск после загрузки и фоновая сеть.

Этот гайд намеренно не использует отключение компонентов приложения. На
современных Android plain shell часто ограничен в таких действиях, а
неаккуратное отключение providers/services может сломать запуск приложения.

## Что запрашивает Yandex Maps

Проверенная версия Yandex Maps запрашивает широкий набор разрешений. Практически
их удобно делить на две группы: install-time permissions и runtime permissions.

### Install-time permissions, которые остаются `granted=true`

Эти разрешения были `granted=true` на тестовом Android 16. Большинство из них
нельзя отозвать через `pm revoke`, потому что Android выдает их при установке
или они относятся к системным/SDK-интеграциям.

| Разрешение                                                               | Почему важно                                                                                             |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| `android.permission.INTERNET`                                            | Онлайн-карты, поиск, маршруты, SDK-трафик, реклама, телеметрия.                                          |
| `android.permission.ACCESS_NETWORK_STATE`                                | Проверка состояния сети.                                                                                 |
| `android.permission.ACCESS_WIFI_STATE`                                   | Проверка состояния Wi-Fi.                                                                                |
| `android.permission.CHANGE_WIFI_STATE`                                   | Можно ограничить через AppOps на тестовом устройстве.                                                    |
| `android.permission.WAKE_LOCK`                                           | Может удерживать CPU активным для сервисов/задач.                                                        |
| `android.permission.RECEIVE_BOOT_COMPLETED`                              | Получение события загрузки системы; на тестовом Android 16 не блокируется через `BOOT_COMPLETED` AppOps. |
| `android.permission.FOREGROUND_SERVICE`                                  | Foreground services.                                                                                     |
| `android.permission.FOREGROUND_SERVICE_LOCATION`                         | Тип foreground-сервиса для геолокации. Реальный доступ режется отзывом runtime location.                 |
| `android.permission.FOREGROUND_SERVICE_CAMERA`                           | Тип foreground-сервиса для камеры. Реальный доступ режется отзывом runtime camera.                       |
| `android.permission.FOREGROUND_SERVICE_DATA_SYNC`                        | Foreground-сервис для синхронизации данных.                                                              |
| `android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK`                   | Foreground-сервис для media playback.                                                                    |
| `android.permission.ACCESS_ADSERVICES_TOPICS`                            | Google Privacy Sandbox Topics API.                                                                       |
| `android.permission.ACCESS_ADSERVICES_ATTRIBUTION`                       | Google attribution/measurement API.                                                                      |
| `android.permission.ACCESS_ADSERVICES_AD_ID`                             | Доступ к AdServices advertising ID.                                                                      |
| `com.google.android.gms.permission.AD_ID`                                | Доступ к Google Advertising ID.                                                                          |
| `com.google.android.gms.permission.ACTIVITY_RECOGNITION`                 | Интеграция activity recognition через Google Play Services.                                              |
| `com.google.android.c2dm.permission.RECEIVE`                             | Push-сообщения.                                                                                          |
| `com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE` | Install referrer tracking.                                                                               |
| `android.permission.SCHEDULE_EXACT_ALARM`                                | Exact alarms; ограничивается через AppOps.                                                               |
| `android.permission.MANAGE_ACCOUNTS`                                     | Интеграция аккаунтов.                                                                                    |
| `android.permission.AUTHENTICATE_ACCOUNTS`                               | Интеграция аккаунтов.                                                                                    |
| `android.permission.USE_CREDENTIALS`                                     | Работа с credentials.                                                                                    |
| `com.yandex.permission.READ_CREDENTIALS`                                 | Интеграция Yandex credentials.                                                                           |
| `android.permission.READ_SYNC_SETTINGS`                                  | Чтение настроек синхронизации.                                                                           |
| `android.permission.WRITE_SYNC_SETTINGS`                                 | Изменение настроек синхронизации.                                                                        |
| `android.permission.DETECT_SCREEN_CAPTURE`                               | Детектирование записи/скриншота экрана.                                                                  |
| `android.permission.NFC`                                                 | NFC-функции.                                                                                             |
| `android.permission.MODIFY_AUDIO_SETTINGS`                               | Управление аудио-поведением.                                                                             |
| `android.permission.VIBRATE`                                             | Вибрация.                                                                                                |
| `android.permission.USE_BIOMETRIC`                                       | Биометрические сценарии.                                                                                 |
| `android.permission.USE_FINGERPRINT`                                     | Legacy fingerprint-сценарии.                                                                             |
| `com.android.vending.BILLING`                                            | In-app billing.                                                                                          |
| `com.android.alarm.permission.SET_ALARM`                                 | Интеграция с будильниками/alarms.                                                                        |
| `androidx.car.app.ACCESS_SURFACE`                                        | Android Auto / car integration.                                                                          |
| `androidx.car.app.NAVIGATION_TEMPLATES`                                  | Android Auto navigation templates.                                                                       |
| `com.android.launcher.permission.INSTALL_SHORTCUT`                       | Создание ярлыков лаунчера.                                                                               |

### Runtime permissions, которые можно отозвать

Эти разрешения были `granted=false` после hardening на тестовом устройстве. Это
основная группа, которую обычный ADB может отозвать через `pm revoke`.

| Разрешение                                           | Что изменится после отзыва                                                 |
| ---------------------------------------------------- | -------------------------------------------------------------------------- |
| `android.permission.ACCESS_FINE_LOCATION`            | Не будет точного текущего местоположения. Ручной поиск по карте работает.  |
| `android.permission.ACCESS_COARSE_LOCATION`          | Не будет примерного текущего местоположения.                               |
| `android.permission.ACCESS_BACKGROUND_LOCATION`      | Не будет фоновой геолокации.                                               |
| `android.permission.CAMERA`                          | Не будут работать QR/фото-функции через камеру.                            |
| `android.permission.RECORD_AUDIO`                    | Не будет доступа к микрофону для голосового ввода.                         |
| `android.permission.READ_CONTACTS`                   | Не будет доступа к контактам.                                              |
| `android.permission.CALL_PHONE`                      | Приложение не сможет напрямую совершать звонки.                            |
| `android.permission.POST_NOTIFICATIONS`              | Не будет уведомлений; это может затронуть навигационные alert-уведомления. |
| `android.permission.READ_MEDIA_IMAGES`               | Не будет прямого доступа к изображениям.                                   |
| `android.permission.READ_MEDIA_VIDEO`                | Не будет прямого доступа к видео.                                          |
| `android.permission.READ_MEDIA_VISUAL_USER_SELECTED` | Не будет доступа к выбранным visual media.                                 |
| `android.permission.ACCESS_MEDIA_LOCATION`           | Не будет доступа к location metadata фото/видео.                           |
| `android.permission.ACTIVITY_RECOGNITION`            | Не будет распознавания активности/движения.                                |
| `android.permission.BLUETOOTH_SCAN`                  | Не будет Bluetooth-сканирования.                                           |
| `android.permission.BLUETOOTH_CONNECT`               | Не будет доступа к Bluetooth-подключениям.                                 |
| `android.permission.BLUETOOTH_ADVERTISE`             | Не будет Bluetooth advertising.                                            |
| `com.google.android.gms.permission.CAR_SPEED`        | Не будет car speed permission.                                             |

### Наблюдаемое поведение после hardening

После применения ограничений приложение успешно запускалось на тестовом Android 16. Fatal crash по Yandex Maps в проверенном окне logcat найден не был.

При запуске в foreground приложение все равно поднимало несколько процессов и
сервисов:

- основной процесс: `ru.yandex.yandexmaps`;
- процесс аккаунта: `ru.yandex.yandexmaps:passport`;
- analytics process/service: `ru.yandex.yandexmaps:AppMetrica` /
  `io.appmetrica.analytics.internal.AppMetricaService`.

В logcat также был виден foreground DNS/network activity для Yandex endpoints,
пока приложение открыто. Это ожидаемо: Android
`restrict-background-blacklist` не блокирует foreground-трафик.

Если геолокация отозвана, Yandex Maps логирует обработанные `SecurityException`
при попытке стартовать location providers. Приложение остается запущенным, но
функции текущего местоположения и навигации будут затронуты.

## Перед началом

Проверьте, что ADB видит устройство:

```bash
adb devices
```

Задайте переменную с пакетом и получите UID приложения:

```bash
PACKAGE="ru.yandex.yandexmaps"
adb shell dumpsys package "$PACKAGE" | grep "appId="
```

Пример с тестового устройства:

```text
appId=10368
```

Используйте свое значение. Не называйте переменную `UID`: в bash/zsh это имя
обычно readonly.

```bash
APP_UID=10368
```

## Шаг 1: отозвать runtime permissions

Эти команды убирают dangerous permissions, которые не нужны для базового
ручного использования карты. Если вам нужна live-навигация по текущему
местоположению, не отзывайте `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`
или выдавайте геолокацию только "while using the app" через настройки Android.

```bash
adb shell pm revoke "$PACKAGE" android.permission.CAMERA
adb shell pm revoke "$PACKAGE" android.permission.RECORD_AUDIO
adb shell pm revoke "$PACKAGE" android.permission.READ_CONTACTS
adb shell pm revoke "$PACKAGE" android.permission.CALL_PHONE
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_FINE_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_COARSE_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_BACKGROUND_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.ACCESS_MEDIA_LOCATION
adb shell pm revoke "$PACKAGE" android.permission.READ_MEDIA_IMAGES
adb shell pm revoke "$PACKAGE" android.permission.READ_MEDIA_VIDEO
adb shell pm revoke "$PACKAGE" android.permission.READ_MEDIA_VISUAL_USER_SELECTED
adb shell pm revoke "$PACKAGE" android.permission.ACTIVITY_RECOGNITION
adb shell pm revoke "$PACKAGE" android.permission.BLUETOOTH_SCAN
adb shell pm revoke "$PACKAGE" android.permission.BLUETOOTH_CONNECT
adb shell pm revoke "$PACKAGE" android.permission.BLUETOOTH_ADVERTISE
adb shell pm revoke "$PACKAGE" android.permission.POST_NOTIFICATIONS
```

На некоторых версиях Android команда может сообщить, что разрешение не
changeable или не запрошено приложением. Это нормально: переходите к следующей
команде.

Проверка:

```bash
adb shell dumpsys package "$PACKAGE" | grep "granted=false"
```

## Шаг 2: отключить Advertising ID и AdServices

Эти команды глобальные. Они влияют на все приложения на устройстве, а не только
на Yandex Maps. Используйте их только если это приемлемо.

```bash
adb shell settings put secure advertising_id "00000000-0000-0000-0000-000000000000"

adb shell device_config put adservices global_kill_switch true
adb shell device_config put adservices adid_kill_switch true
adb shell device_config put adservices measurement_kill_switch true
adb shell device_config put adservices adservice_enabled false
adb shell device_config put adservices adservice_system_service_enabled false

adb shell device_config set_sync_disabled_for_tests persistent
```

Проверка:

```bash
adb shell settings get secure advertising_id
adb shell device_config get adservices global_kill_switch
adb shell device_config get adservices adid_kill_switch
adb shell device_config get adservices measurement_kill_switch
adb shell device_config get adservices adservice_enabled
adb shell device_config get adservices adservice_system_service_enabled
adb shell device_config get_sync_disabled_for_tests
```

Ожидаемые hardened-значения:

```text
00000000-0000-0000-0000-000000000000
true
true
true
false
false
persistent
```

## Шаг 3: ограничить AppOps

AppOps полезны для поведения и разрешений, которые нельзя чисто убрать через
`pm revoke`.

```bash
# Фоновое выполнение
adb shell cmd appops set "$PACKAGE" RUN_IN_BACKGROUND deny
adb shell cmd appops set "$PACKAGE" RUN_ANY_IN_BACKGROUND deny
adb shell cmd appops set "$PACKAGE" START_FOREGROUND deny

# Запланированные задачи
adb shell cmd appops set "$PACKAGE" SCHEDULE_EXACT_ALARM deny

# Идентификаторы и доступ к аккаунтоподобным данным
adb shell cmd appops set "$PACKAGE" GET_ACCOUNTS deny
adb shell cmd appops set "$PACKAGE" READ_DEVICE_IDENTIFIERS deny
adb shell cmd appops set "$PACKAGE" READ_PHONE_STATE deny

# Буфер обмена и изменение Wi-Fi state
adb shell cmd appops set "$PACKAGE" READ_CLIPBOARD deny
adb shell cmd appops set "$PACKAGE" CHANGE_WIFI_STATE deny

# Уведомления. Опционально: может сломать навигационные/status alerts.
adb shell cmd appops set "$PACKAGE" POST_NOTIFICATION deny
```

На Android 15/16 некоторые runtime-linked операции также хранятся на UID-level.
Package-level команда может вернуть success, но `appops get` все равно покажет
effective package-level `allow`. Добавьте UID-level форму:

```bash
adb shell cmd appops set --uid "$PACKAGE" READ_PHONE_STATE deny
adb shell cmd appops set --uid "$PACKAGE" ACTIVITY_RECOGNITION deny
adb shell cmd appops set --uid "$PACKAGE" POST_NOTIFICATION deny
```

Автозапуск после boot зависит от версии Android:

```bash
adb shell cmd appops set "$PACKAGE" BOOT_COMPLETED ignore
```

На тестовом Android 16 эта команда вернула:

```text
Error: Unknown operation string: BOOT_COMPLETED
```

Если видите такую ошибку, считайте `RECEIVE_BOOT_COMPLETED` не блокируемым через
plain ADB AppOps на вашей прошивке.

Проверка:

```bash
adb shell cmd appops get "$PACKAGE"
adb shell cmd appops get --uid "$PACKAGE"
```

Полезные hardened-строки:

```text
RUN_IN_BACKGROUND: deny
RUN_ANY_IN_BACKGROUND: deny
START_FOREGROUND: deny
READ_CLIPBOARD: deny
CHANGE_WIFI_STATE: deny
READ_DEVICE_IDENTIFIERS: deny
SCHEDULE_EXACT_ALARM: deny
```

Для runtime permissions, которые были отозваны через `pm revoke`, Android может
показывать смешанную картину в AppOps: UID mode `ignore`, но package mode
`allow`. В таком случае для фактического runtime grant state ориентируйтесь на
`dumpsys package`.

## Шаг 4: перевести приложение в standby bucket `restricted`

Это переводит приложение в самый строгий обычный standby bucket Android.
Ограничение помогает подавить фоновые jobs, WorkManager, datatransport и
analytics scheduling, пока приложение не используется активно.

```bash
adb shell am set-standby-bucket "$PACKAGE" restricted
```

Проверка:

```bash
adb shell am get-standby-bucket "$PACKAGE"
```

Ожидаемо:

```text
45
```

Android может повысить bucket после активного использования приложения. После
обновлений или долгой активной сессии команду стоит повторить.

## Шаг 5: заблокировать фоновую сеть

Это блокирует сеть только тогда, когда Yandex Maps не находится в foreground.

```bash
adb shell cmd netpolicy add restrict-background-blacklist "$APP_UID"
```

Проверка:

```bash
adb shell cmd netpolicy list restrict-background-blacklist
```

Ожидаемый пример:

```text
Restrict background blacklisted UIDs: 10368
```

Используйте свой UID, а не `10368`, если ваше устройство показывает другое
значение.

## All-in-one script

Перед запуском прочитайте скрипт. Он предполагает максимально строгий ADB-only
режим: без уведомлений и без разрешения на геолокацию приложения.

```bash
#!/usr/bin/env bash
set -euo pipefail

PACKAGE="ru.yandex.yandexmaps"
APP_UID="$(adb shell dumpsys package "$PACKAGE" | sed -n 's/.*appId=//p' | head -n 1 | tr -d '\r')"

if ! [[ "$APP_UID" =~ ^[0-9]+$ ]]; then
  echo "Error: Could not detect numeric APP_UID for $PACKAGE. Is the app installed?" >&2
  exit 1
fi

echo "[0/5] Package: $PACKAGE"
echo "[0/5] UID: $APP_UID"

echo "[1/5] Revoking runtime permissions"
RUNTIME_PERMS=(
  CAMERA
  RECORD_AUDIO
  READ_CONTACTS
  CALL_PHONE
  ACCESS_FINE_LOCATION
  ACCESS_COARSE_LOCATION
  ACCESS_BACKGROUND_LOCATION
  ACCESS_MEDIA_LOCATION
  READ_MEDIA_IMAGES
  READ_MEDIA_VIDEO
  READ_MEDIA_VISUAL_USER_SELECTED
  ACTIVITY_RECOGNITION
  BLUETOOTH_SCAN
  BLUETOOTH_CONNECT
  BLUETOOTH_ADVERTISE
  POST_NOTIFICATIONS
)

for perm in "${RUNTIME_PERMS[@]}"; do
  adb shell pm revoke "$PACKAGE" "android.permission.$perm" 2>/dev/null \
    && echo "  ok: $perm" \
    || echo "  skip: $perm"
done

echo "[2/5] Disabling AdServices globally"
adb shell settings put secure advertising_id "00000000-0000-0000-0000-000000000000"
adb shell device_config put adservices global_kill_switch true
adb shell device_config put adservices adid_kill_switch true
adb shell device_config put adservices measurement_kill_switch true
adb shell device_config put adservices adservice_enabled false
adb shell device_config put adservices adservice_system_service_enabled false
adb shell device_config set_sync_disabled_for_tests persistent

echo "[3/5] Restricting AppOps"
APPOPS=(
  RUN_IN_BACKGROUND
  RUN_ANY_IN_BACKGROUND
  START_FOREGROUND
  SCHEDULE_EXACT_ALARM
  GET_ACCOUNTS
  READ_DEVICE_IDENTIFIERS
  READ_PHONE_STATE
  READ_CLIPBOARD
  CHANGE_WIFI_STATE
  POST_NOTIFICATION
)

for op in "${APPOPS[@]}"; do
  adb shell cmd appops set "$PACKAGE" "$op" deny 2>/dev/null \
    && echo "  ok: $op" \
    || echo "  skip: $op"
done

UID_APPOPS=(READ_PHONE_STATE ACTIVITY_RECOGNITION POST_NOTIFICATION)
for op in "${UID_APPOPS[@]}"; do
  adb shell cmd appops set --uid "$PACKAGE" "$op" deny 2>/dev/null \
    && echo "  ok: $op (--uid)" \
    || echo "  skip: $op (--uid)"
done

adb shell cmd appops set "$PACKAGE" BOOT_COMPLETED ignore 2>/dev/null \
  && echo "  ok: BOOT_COMPLETED" \
  || echo "  skip: BOOT_COMPLETED unsupported on this build"

echo "[4/5] Setting standby bucket"
adb shell am set-standby-bucket "$PACKAGE" restricted

echo "[5/5] Blocking background network"
adb shell cmd netpolicy add restrict-background-blacklist "$APP_UID"

echo
echo "Verification:"
adb shell am get-standby-bucket "$PACKAGE"
adb shell cmd netpolicy list restrict-background-blacklist
adb shell cmd appops get "$PACKAGE" | grep -E "RUN_IN_BACKGROUND|RUN_ANY_IN_BACKGROUND|START_FOREGROUND|READ_CLIPBOARD|CHANGE_WIFI_STATE|READ_DEVICE_IDENTIFIERS|SCHEDULE_EXACT_ALARM"
```

## Опционально: оставить foreground-геолокацию

Если вам нужна live-навигация, скорее всего понадобится foreground location.
Практичный компромисс:

- оставить `ACCESS_BACKGROUND_LOCATION` отозванным;
- разрешить approximate или precise location только "while using the app" в
  настройках Android;
- оставить ограничения на background execution, background network, exact
  alarms, identifiers, clipboard и AdServices.

Выдача foreground location - это выбор удобства, а не требование для ручного
просмотра карты.

## Что остается без root или Shizuku

Некоторые вещи остаются вне контроля plain ADB:

| Механизм                               | Почему остается                                                                                                      |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Foreground network telemetry           | Background netpolicy не применяется, пока приложение открыто.                                                        |
| AppMetrica service в foreground        | Проверенное приложение запускало `io.appmetrica.analytics.internal.AppMetricaService`, пока было foreground.         |
| Install referrer permission            | Install-time permission Google Play.                                                                                 |
| Account permissions                    | `MANAGE_ACCOUNTS`, `AUTHENTICATE_ACCOUNTS`, `USE_CREDENTIALS` и Yandex credential permissions являются install-time. |
| Boot permission на тестовом Android 16 | AppOps operation `BOOT_COMPLETED` была недоступна.                                                                   |
| `DETECT_SCREEN_CAPTURE`                | System-level permission.                                                                                             |
| Foreground service types               | Install-time declarations; runtime permissions могут нейтрализовать camera/location access, но не сами declarations. |
| Component-level SDK providers/services | Plain shell component disabling ограничен на современных Android и может сломать запуск.                             |

Для контроля foreground-телеметрии без root реалистичный следующий слой -
локальный VPN firewall или DNS blocklist. Это лучше документировать отдельно,
потому что блокировка доменов может по-разному ломать карты, поиск, маршруты,
логин, платежи и Android Auto.

## Откат

Убрать ограничение фоновой сети:

```bash
adb shell cmd netpolicy remove restrict-background-blacklist "$APP_UID"
```

Вернуть standby bucket:

```bash
adb shell am set-standby-bucket "$PACKAGE" active
```

Сбросить AppOps для приложения:

```bash
adb shell cmd appops reset "$PACKAGE"
```

Вернуть AdServices sync и значения, если вы осознанно отключали их глобально:

```bash
adb shell device_config set_sync_disabled_for_tests none
adb shell device_config put adservices global_kill_switch false
adb shell device_config put adservices adid_kill_switch false
adb shell device_config put adservices measurement_kill_switch false
adb shell device_config put adservices adservice_enabled true
adb shell device_config put adservices adservice_system_service_enabled true
```

Runtime permissions можно снова выдать через настройки Android. По возможности
выдавайте только режим "while using the app".

## Заключение

На Android 14-16 без root и Shizuku Yandex Maps можно заметно ужать:

- отозвать dangerous runtime permissions;
- глобально отключить AdServices и Advertising ID;
- ограничить background execution и exact alarms;
- заблокировать фоновую сеть по UID;
- перевести приложение в standby bucket `restricted`.

Это не удаляет foreground-телеметрию полностью. Но это снижает пассивный сбор
данных, когда приложение закрыто или простаивает, и ограничивает доступ к
сенсорам, медиа, контактам, phone state, identifiers, clipboard и background
location.
