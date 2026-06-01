# Note on Yandex Smart Home (Умный Дом / IOT)

**Package:** `com.yandex.iot`

During the development of this project, we analyzed the permissions requested by the Yandex Smart Home app. It frequently requests:
- `BLUETOOTH_SCAN` and `ACCESS_WIFI_STATE` (To find smart bulbs, sockets, and speakers).
- `RECORD_AUDIO` (For voice commands).
- Background execution and wakelocks (To maintain connections with IoT devices).

**Why it is excluded from the script:**
Applying strict privacy hardenings (like blocking background execution or network access) to this specific app entirely breaks its core functionality. If you restrict these permissions, the app will fail to detect devices on your local network or execute automated routines. 

If you use Yandex Smart Home devices, you must accept the data collection associated with this app. If privacy is a strict requirement, we recommend migrating to open-source, local-first IoT solutions like Home Assistant.