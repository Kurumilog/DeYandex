# Яндекс Браузер (`com.yandex.browser`)

Яндекс Браузер тесно интегрирован в экосистему Яндекса и выступает центральным узлом для сбора данных, межпрограммного отслеживания и телеметрии. Приложение часто работает в фоновом режиме для синхронизации данных, предварительной загрузки лент (например, Яндекс Дзен) и поддержания постоянных соединений.

Если вы не можете полностью удалить его (например, через Universal Android Debloater: `pm uninstall -k --user 0 com.yandex.browser`), вы можете жестко ограничить его фоновую активность и доступ к датчикам.

## Рекомендуемые ограничения AppOps

Примените следующие команды через ADB, чтобы ограничить права Браузера, не нарушая основной функционал веб-серфинга.

### 1. Остановка фоновой работы и пробуждений

Эти команды не позволяют браузеру запускать фоновые службы и удерживать устройство в активном состоянии, что экономит батарею и снижает отслеживание.

```sh
adb shell cmd appops set com.yandex.browser RUN_IN_BACKGROUND ignore
adb shell cmd appops set com.yandex.browser RUN_ANY_IN_BACKGROUND ignore
adb shell cmd appops set com.yandex.browser WAKE_LOCK ignore
```

### 2. Изоляция датчиков (Геолокация, Камера, Микрофон)

Если вы не используете Браузер для AR-поиска, точной навигации или голосового помощника "Алиса", отключите эти датчики.

```sh
adb shell cmd appops set com.yandex.browser ACCESS_FINE_LOCATION ignore
adb shell cmd appops set com.yandex.browser CAMERA ignore
adb shell cmd appops set com.yandex.browser RECORD_AUDIO ignore
```

### 3. Защита буфера обмена

Предотвращает скрытое чтение буфера обмена (в котором могут быть пароли, коды 2FA) в фоновом режиме.

```sh
adb shell cmd appops set com.yandex.browser READ_CLIPBOARD ignore
```
