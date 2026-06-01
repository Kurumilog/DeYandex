# Яндекс Маркет (`ru.beru.android`)

Яндекс Маркет (ранее Беру) собирает данные о ваших контактах, Bluetooth-окружении и использует агрессивную аналитику AppMetrica.

## Рекомендуемые ограничения AppOps

### 1. Изоляция личных данных

Маркет запрашивает доступ к контактам и сканированию Bluetooth-устройств. Это не требуется для совершения покупок.

```sh
# Контакты
adb shell cmd appops set ru.beru.android READ_CONTACTS ignore

# Bluetooth
adb shell cmd appops set ru.beru.android BLUETOOTH_SCAN ignore
```

### 2. Изоляция сенсоров

```sh
adb shell cmd appops set ru.beru.android FINE_LOCATION ignore
adb shell cmd appops set ru.beru.android CAMERA ignore
adb shell cmd appops set ru.beru.android RECORD_AUDIO ignore
```

### 3. Ограничение фоновой работы

```sh
adb shell cmd appops set ru.beru.android RUN_IN_BACKGROUND ignore
adb shell cmd appops set ru.beru.android WAKE_LOCK ignore
adb shell am set-standby-bucket ru.beru.android restricted
```
