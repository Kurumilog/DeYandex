# Яндекс Музыка (`ru.yandex.music`)

Яндекс Музыка часто расходует много заряда батареи из-за удержания аудиоблокировок (wakelocks) даже после паузы воспроизведения. Также используется выделенный процесс `:Metrica` для выгрузки аналитики.

## Рекомендуемые ограничения AppOps

_Осторожно:_ Команда `RUN_IN_BACKGROUND ignore` может сломать фоновое воспроизведение на устройствах вроде MIUI/ColorOS. Поэтому мы ограничиваем только датчики и wakelocks.

### 1. Снижение расхода батареи (Wakelocks)

_Внимание:_ На старых устройствах это может остановить музыку при выключении экрана. Проверьте на своем устройстве. Если музыка заикается, верните `allow`.

```sh
adb shell cmd appops set ru.yandex.music WAKE_LOCK ignore
```

### 2. Изоляция датчиков и микрофона

Плееру не нужна точная геолокация, доступ к камере и микрофону (если вы не используете голосовой поиск внутри приложения).

```sh
adb shell cmd appops set ru.yandex.music FINE_LOCATION ignore
adb shell cmd appops set ru.yandex.music CAMERA ignore
adb shell cmd appops set ru.yandex.music RECORD_AUDIO ignore
```

### 3. Ограничение ресурсов

Переводит приложение в режим ожидания `restricted`, ограничивая фоновую передачу данных аналитики.

```sh
adb shell am set-standby-bucket ru.yandex.music restricted
```
