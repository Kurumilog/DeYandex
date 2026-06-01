# Hardening Yandex Disk (Яндекс Диск)

Yandex Disk requests extensive permissions, including full access to storage and media files. It often runs in the background to automatically upload photos and scan metadata (EXIF).

## Risks Addressed
- **Background Media Scanning**: Prevents the app from constantly indexing your local files and analyzing photos in the background.
- **Background Battery Drain**: Limits wakelocks caused by auto-sync features when the screen is off.
- **Unnecessary Sensors**: Blocks access to the camera and precise location (often used to tag where photos were taken before uploading).

## Hardening Steps

The interactive script (`deyandex.sh`) applies the following:

1. **Block Background Execution & Wakelocks**
   ```bash
   adb shell cmd appops set ru.yandex.disk RUN_IN_BACKGROUND ignore
   adb shell cmd appops set ru.yandex.disk WAKE_LOCK ignore
   adb shell am set-standby-bucket ru.yandex.disk restricted
   ```
   *Impact*: Automatic photo uploads will only trigger when the app is actively open on your screen.

2. **Isolate Sensors and Media Access**
   ```bash
   adb shell cmd appops set ru.yandex.disk FINE_LOCATION ignore
   adb shell cmd appops set ru.yandex.disk CAMERA ignore
   adb shell cmd appops set ru.yandex.disk READ_EXTERNAL_STORAGE ignore
   adb shell cmd appops set ru.yandex.disk WRITE_EXTERNAL_STORAGE ignore
   adb shell cmd appops set ru.yandex.disk ACCESS_MEDIA_LOCATION ignore
   ```
   *Impact*: Prevents access to EXIF location tags and restricts background storage scanning. You can still manually select and upload files using the Android file picker.