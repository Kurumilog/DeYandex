## 2024-06-13 - [Command Injection via Untrusted Device Output]
**Vulnerability:** The script directly used the output of `adb shell dumpsys package <pkg>` (which runs on the target device) in the host shell script (`uid=$(...)`) and passed it unvalidated to `adb shell cmd netpolicy`. This could theoretically allow command injection or parameter tampering if a malicious app manipulated its `userId` output or if the output was otherwise malformed.
**Learning:** Output from commands executed on connected devices (like `dumpsys`) must be treated as untrusted user input, even if the user initiated the script.
**Prevention:** Always apply strict regex validation (e.g., `^[0-9]+$`) to extract and verify specific data formats (like numeric UIDs) from device output before using them in further commands.

## 2025-02-09 - [Silent Bypass of Security Features via Hidden Carriage Returns]
**Vulnerability:** The previous security fix introduced a regression where the strict regex validation (`^[0-9]+$`) silently failed on valid UIDs because the output from `adb shell dumpsys` included hidden DOS-style carriage returns (`\r`). This caused the script to fail to extract the UID, resulting in the silent bypass of network policy enforcement.
**Learning:** Security validation that does not account for environment-specific encoding (like `\r\n` from adb) can lead to silent failure modes where intended security mechanisms are completely bypassed. Security enhancements can introduce new risks if not thoroughly tested with real-world inputs.
**Prevention:** Always sanitize input by removing environmental artifacts (like using `tr -d '\r'`) before applying strict regex validation, and ensure that security failures are logged or handle gracefully rather than failing silently.
