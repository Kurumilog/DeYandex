## 2024-06-13 - [Command Injection via Untrusted Device Output]
**Vulnerability:** The script directly used the output of `adb shell dumpsys package <pkg>` (which runs on the target device) in the host shell script (`uid=$(...)`) and passed it unvalidated to `adb shell cmd netpolicy`. This could theoretically allow command injection or parameter tampering if a malicious app manipulated its `userId` output or if the output was otherwise malformed.
**Learning:** Output from commands executed on connected devices (like `dumpsys`) must be treated as untrusted user input, even if the user initiated the script.
**Prevention:** Always apply strict regex validation (e.g., `^[0-9]+$`) to extract and verify specific data formats (like numeric UIDs) from device output before using them in further commands.

## 2025-02-09 - [Silent Bypass of Security Features via Hidden Carriage Returns]
**Vulnerability:** The previous security fix introduced a regression where the strict regex validation (`^[0-9]+$`) silently failed on valid UIDs because the output from `adb shell dumpsys` included hidden DOS-style carriage returns (`\r`). This caused the script to fail to extract the UID, resulting in the silent bypass of network policy enforcement.
**Learning:** Security validation that does not account for environment-specific encoding (like `\r\n` from adb) can lead to silent failure modes where intended security mechanisms are completely bypassed. Security enhancements can introduce new risks if not thoroughly tested with real-world inputs.
**Prevention:** Always sanitize input by removing environmental artifacts (like using `tr -d '\r'`) before applying strict regex validation, and ensure that security failures are logged or handle gracefully rather than failing silently.

## 2025-02-09 - [Silent NetPolicy Bypass in Multi-Profile Environments]
**Vulnerability:** The script previously failed to extract UIDs when `grep userId=` returned multiple results (e.g. `10135\n10136`), which happens in multi-profile Android environments like Work Profiles or Dual Messenger. The strictly bounded bash regex validation (`^[0-9]+$`) silently rejected the entire multi-line string. As a result, no UIDs were processed, and critical NetPolicy security restrictions were completely bypassed for all instances of the application.
**Learning:** In Android systems, package attributes (like UIDs) can exist in multiple contexts concurrently. String validation mechanisms in security scripts must anticipate and correctly iterate through array/list outputs. Relying on strict scalar regex validation for outputs that may occasionally be multi-line leads to brittle security enforcement and silent bypasses.
**Prevention:** Always iterate through potentially multiple return values (e.g., using `for uid in $raw_uids`) before applying strict regex validation, and ensure that validation loops log clear security warnings (`>&2`) when expected formats fail or when zero valid targets are found, rather than silently moving on.

## 2026-06-17 - [Path Expansion and Terminal Injection via Untrusted Device Output]
**Vulnerability:** The script used an unquoted `for uid in $raw_uids; do` loop to iterate over untrusted device output, which allowed bash path expansion (globbing). If an attacker provided a glob character like `*`, bash would expand it to filenames in the current directory. Additionally, the script used `echo -e` to log invalid UIDs, which could execute terminal escape sequences (e.g., `\033[2J`), allowing an attacker to manipulate the host terminal.
**Learning:** Using unquoted variables in loops with untrusted data leads to unintentional path expansion (globbing), causing validation against unintended files instead of raw data. `echo -e` poses a risk of terminal injection when printing untrusted data.
**Prevention:** Always use `while IFS= read -r var; do` loops to iterate over lines securely. Use `printf` instead of `echo -e` to safely format and print user-supplied data without executing terminal escape sequences.

## 2025-02-09 - [Path Expansion (Globbing) via Untrusted Output]
**Vulnerability:** The script used an unquoted `for u in $uids; do` loop to iterate over untrusted device output (UIDs). If the output contained a wildcard character (e.g., `*`), bash would perform path expansion, leading to unpredictable behavior or errors rather than correctly processing the UID.
**Learning:** Using unquoted variables in loops with untrusted data leads to unintentional path expansion (globbing), causing validation against unintended files instead of raw data.
**Prevention:** Always use `while IFS= read -r var; do` loops with a heredoc (`<<< "$var"`) to iterate over lines securely.

## 2024-06-21 - [Path Expansion (Globbing) Vulnerability in Array Assignment]
**Vulnerability:** The script previously populated the `devices` array using an unquoted command substitution: `devices=($(adb devices | ...))`. This pattern is vulnerable to path expansion (globbing). If the output (e.g., a manipulated device serial number) contained wildcard characters like `*`, Bash would expand them into matching file names from the current working directory, potentially causing unpredictable logic failure or exploiting subsequent script operations.
**Learning:** Initializing arrays with unquoted command substitutions over untrusted data is unsafe in Bash due to implicit word splitting and path expansion (globbing).
**Prevention:** Use `mapfile` (or `readarray`) such as `mapfile -t arr < <(command)` to safely read lines of untrusted output into a Bash array.

## 2024-06-21 - [Terminal Escape Sequence Injection via echo -e]
**Vulnerability:** The script heavily relied on `echo -e` to format and print colored text to the console, often incorporating bash variables (like app packages, prompts, or warnings). While currently hardcoded, if these variables were ever influenced by untrusted input, an attacker could inject arbitrary terminal escape sequences, potentially altering terminal behavior, clearing screens, or spoofing output.
**Learning:** `echo -e` implicitly interprets escape sequences in its arguments. Using it with variables is an anti-pattern that introduces terminal injection risks.
**Prevention:** Always use `printf` with explicit format specifiers (e.g., `printf "%s\n" "$var"`) for safe string formatting and printing in Bash scripts, especially when variables are involved.

## 2024-06-21 - [TOCTOU Vulnerability in Log File Creation]
**Vulnerability:** The script previously cleared old log files using `rm -f "$LOG_FILE"` followed by `touch "$LOG_FILE"`. This created a Time-Of-Check to Time-Of-Use (TOCTOU) vulnerability where an attacker could create a symlink to a sensitive file between the deletion and the creation, causing subsequent `chmod` and `tee` commands to overwrite the targeted sensitive file.
**Learning:** Sequential file deletion and creation patterns are insecure in shared or attacker-controlled directories due to race conditions.
**Prevention:** Always use atomic file creation operations for sensitive files, such as leveraging bash's noclobber option (`set -C; echo -n > "$LOG_FILE"`) to ensure the file is created safely and fails if a symlink or file already exists.

## 2024-06-21 - [Regex Injection via Unsanitized Package Names]
**Vulnerability:** The script used `grep -q "^package:${pkg}$"` to verify if an app was installed. Because `${pkg}` could contain dots (e.g., `com.yandex.browser`), the dots were interpreted as regex wildcards, allowing unintended partial matches.
**Learning:** Interpolating variables into regular expressions without escaping special characters leads to Regex Injection.
**Prevention:** Use `grep -F -x -q` to perform exact, fixed-string line matching instead of relying on regex patterns with unescaped variables.
## 2024-05-24 - Unquoted variables in adb shell wrappers
**Vulnerability:** Variables like `$pkg` were passed unquoted to adb shell commands (e.g. `adbs cmd appops set $pkg RUN_IN_BACKGROUND ignore`), which leaves them open to word splitting and globbing.
**Learning:** Shell scripts interacting with sensitive system tools (like adb shell/appops) require strict variable quoting to avoid unexpected execution behaviors or command injection.
**Prevention:** Always wrap variables passed as arguments to shell commands or wrappers in double quotes (e.g. `"$pkg"`).
## 2024-06-23 - [Information Exposure via Log Creation Race Condition]
**Vulnerability:** The script created a log file securely using `set -C; echo -n > "$LOG_FILE"` but did not set the umask first. This created a race condition where the newly created file could temporarily inherit default system permissions (e.g., 644) and be readable by other users on the system, exposing potentially sensitive device data, before the subsequent `chmod 600` command was executed.
**Learning:** Atomic file creation prevents overwriting/symlink attacks, but it does not inherently guarantee secure file permissions from the moment of creation if the environment's `umask` is permissive.
**Prevention:** Always set an explicit `umask` (e.g., `umask 077`) as part of the atomic file creation subshell (e.g., `(umask 077; set -C; echo -n > "$LOG_FILE")`) to ensure the file is created with strict permissions immediately, eliminating the race condition before `chmod` is called.

## 2024-06-25 - [Host System Exposure via Root Script Execution]
**Vulnerability:** The script interacts with untrusted output from external Android devices via ADB but did not restrict execution privileges. If a user ran the script as root (e.g., via `sudo`) and the script processed a malicious payload from an infected device, the attacker could theoretically achieve local privilege escalation and full control of the host machine.
**Learning:** Scripts interfacing with external untrusted sources must strictly enforce the principle of least privilege.
**Prevention:** Always add a root execution check (e.g., `[ "$EUID" -eq 0 ]`) to scripts that do not explicitly require root privileges to prevent accidental execution with elevated permissions.

## 2026-06-26 - [Arbitrary File Overwrite via tee TOCTOU Symlink Attack]
**Vulnerability:** The script created a log file securely using `set -C; echo -n > "$LOG_FILE"`, but subsequently used `exec > >(tee "$LOG_FILE") 2>&1`. Because `tee` opens the file by its path name rather than using a securely opened file descriptor, an attacker could delete the file and replace it with a symlink to a sensitive file in the brief window between the atomic creation and the execution of `tee`. `tee` would then follow the symlink, overwriting the sensitive file with the script's output.
**Learning:** File path re-evaluation in shell utilities (like `tee`) after a secure atomic file creation re-introduces TOCTOU symlink vulnerabilities.
**Prevention:** When securely opening a file with `set -C`, obtain a file descriptor (e.g., `exec 3> "$LOG_FILE"`) and pass the file descriptor path (e.g., `/dev/fd/3`) to subsequent tools like `tee` to prevent path re-evaluation and symlink attacks.
