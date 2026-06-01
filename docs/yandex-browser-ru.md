# Яндекс Браузер (`com.yandex.browser`)

Яндекс Браузер тесно интегрирован в экосистему Яндекса и выступает центральным узлом для сбора данных, межпрограммного отслеживания и телеметрии. Приложение часто работает в фоновом режиме для синхронизации данных, предварительной загрузки лент (например, Яндекс Дзен) и поддержания постоянных соединений.

Если вы не можете полностью удалить его (например, через Universal Android Debloater: `pm uninstall -k --user 0 com.yandex.browser`), вы можете жестко ограничить его фоновую активность и доступ к датчикам.

## Рекомендуемые ограничения AppOps

Примените следующие команды через ADB, чтобы ограничить права Браузера, не нарушая основной функционал веб-серфинга.

### 1. Остановка фоновой работы и пробуждений

Эти команды не позволяют браузеру запускать фоновые службы и удерживать устройство в активном состоянии, что экономит батарею и снижает отслеживание. Дополнительно приложение переводится в режим ожидания `restricted`.

```sh
adb shell cmd appops set com.yandex.browser RUN_IN_BACKGROUND ignore
adb shell cmd appops set com.yandex.browser RUN_ANY_IN_BACKGROUND ignore
adb shell cmd appops set com.yandex.browser WAKE_LOCK ignore
adb shell am set-standby-bucket com.yandex.browser restricted
```

### 2. Изоляция датчиков и личных данных

Если вы не используете Браузер для AR-поиска или голосового помощника "Алиса", отключите эти датчики. Также блокируется доступ к календарю и идентификаторам телефона.

```sh
# Геолокация, камера и микрофон
adb shell cmd appops set com.yandex.browser FINE_LOCATION ignore
adb shell cmd appops set com.yandex.browser CAMERA ignore
adb shell cmd appops set com.yandex.browser RECORD_AUDIO ignore

# Личные данные и идентификаторы
adb shell cmd appops set com.yandex.browser READ_CALENDAR ignore
adb shell cmd appops set com.yandex.browser READ_PHONE_STATE ignore
```

### 3. Защита файлов и медиа

Блокирует доступ к фотографиям и файлам на устройстве, чтобы предотвратить их сканирование модулями аналитики.

```sh
adb shell cmd appops set com.yandex.browser READ_EXTERNAL_STORAGE ignore
adb shell cmd appops set com.yandex.browser WRITE_EXTERNAL_STORAGE ignore
adb shell cmd appops set com.yandex.browser ACCESS_MEDIA_LOCATION ignore
```

### 4. Защита буфера обмена

Предотвращает скрытое чтение буфера обмена (в котором могут быть пароли, коды 2FA) в фоновом режиме.

```sh
adb shell cmd appops set com.yandex.browser READ_CLIPBOARD ignore
```
