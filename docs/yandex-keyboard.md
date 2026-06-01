# Hardening Yandex Keyboard (Яндекс Клавиатура)

**Package:** `ru.yandex.androidkeyboard`

Keyboards are arguably the most sensitive components on a smartphone, as they have access to every keystroke (passwords, messages, search queries). While Yandex states data is anonymized, the app includes AppMetrica telemetry.

## Risks Addressed
- **Keystroke Telemetry**: Preventing the keyboard from sending typing statistics to Yandex servers.
- **Voice Input Data**: Blocking background access to the microphone.
- **Contact Harvesting**: Preventing the keyboard from reading your contacts to "improve auto-correction".

## Hardening Steps

The interactive script (`deyandex.sh`) applies two levels of hardening for the keyboard:

### Level 1: Sensor Isolation
```bash
adb shell cmd appops set ru.yandex.androidkeyboard RECORD_AUDIO ignore
adb shell cmd appops set ru.yandex.androidkeyboard READ_CONTACTS ignore
```
*Impact*: Voice typing will be disabled. Auto-correction will not suggest names from your contact book.

### Level 2: Complete Network Isolation (Experimental)
Since keyboards inherently need to process all text, the most secure approach is to cut off its internet access entirely using Android's NetPolicy.
```bash
adb shell cmd netpolicy set restrict-background true <UID>
adb shell cmd netpolicy set-statistics --uid <UID> --metered-network-restricted true
```
*Impact*: The keyboard becomes 100% offline. It will not be able to sync dictionaries across devices, download new themes, or send telemetry. This is highly recommended for privacy-conscious users.

## Note on Custom Dictionaries
Permissions `READ_USER_DICTIONARY` and `WRITE_USER_DICTIONARY` were deprecated/removed in newer Android versions, so they are not modified via AppOps.