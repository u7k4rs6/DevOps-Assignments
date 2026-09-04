# Shell Scripting Assignment

**Name:** Utkarsh Bahuguna &nbsp;&nbsp;**Enrollment Number:** 10161

## Task: System Information Script

**Script:** [`sysinfo.sh`](sysinfo.sh)

The script prints the date, hostname and username; shows disk, memory and process usage; asks the user for a directory name; creates that directory and a file inside it; and writes the process list into the file using output redirection.

### The script

```bash
#!/bin/bash
#
# sysinfo.sh - System Information Report
# DevOps Assignment 02: Shell Scripting
# Author: Utkarsh Bahuguna (10161)
#
# Demonstrates: variables, command substitution, user input (read),
# directory/file creation, and output redirection.

set -u

# ---------- Variables (command substitution) ----------
current_date=$(date)
host_name=$(hostname)
current_user=$(whoami)
kernel_version=$(uname -r)
up_time=$(uptime -p)

# ---------- Section 1: identity ----------
echo "=============================================="
echo "           SYSTEM INFORMATION REPORT          "
echo "=============================================="
echo "Current date : $current_date"
echo "Hostname     : $host_name"
echo "Current user : $current_user"
echo "Kernel       : $kernel_version"
echo "Uptime       : $up_time"

# ---------- Section 2: disk usage ----------
echo
echo "----- Disk Usage (df -h) -----"
df -h --exclude-type=tmpfs --exclude-type=devtmpfs

# ---------- Section 3: memory ----------
echo
echo "----- Memory Usage (free -h) -----"
free -h

# ---------- Section 4: running processes ----------
echo
echo "----- Running Processes (top 10 by CPU) -----"
ps aux --sort=-%cpu | head -n 10 | cut -c 1-100   # cut keeps the table readable

# ---------- Section 5: user input ----------
echo
read -rp "Enter a name for your report directory: " dir_name

# Fall back to a default if the user just pressed Enter
if [ -z "$dir_name" ]; then
    dir_name="sysreport"
    echo "No name given - using default: $dir_name"
fi

# ---------- Section 6: create directory + file ----------
mkdir -p "$dir_name"
report_file="$dir_name/testProcess.txt"
touch "$report_file"

# ---------- Section 7: output redirection ----------
{
    echo "Process snapshot taken on $current_date"
    echo "Host: $host_name   User: $current_user"
    echo
} > "$report_file"          # > truncates and writes the header

ps aux >> "$report_file"    # >> appends the full process list

echo
echo "Process list saved to $report_file"
echo "Lines written: $(wc -l < "$report_file")"
```

### Design notes

| Choice | Why |
|---|---|
| `set -u` | Abort on an undefined variable rather than silently expanding to an empty string - a `mkdir ""` bug is much harder to spot than an error message. |
| `$(...)` command substitution | Captures each command's output into a variable once, so the same value is reused instead of re-running `date` and getting two different timestamps. |
| `read -rp` | `-r` stops backslashes in the input being treated as escapes; `-p` prints the prompt without a separate `echo`. |
| `[ -z "$dir_name" ]` fallback | Pressing Enter with no input would otherwise create nothing and write to `/testProcess.txt`. |
| `mkdir -p` | Idempotent - re-running the script does not fail on an existing directory. |
| `cut -c 1-100` on `ps` | Chrome's command lines are ~2000 characters wide and destroy the table layout. |
| `>` then `>>` | `>` truncates and writes the header, `>>` appends the process list - both forms of redirection demonstrated. |
| Quoting `"$dir_name"` everywhere | A directory name with a space would otherwise split into two arguments. |

### How to run

```bash
chmod +x sysinfo.sh
./sysinfo.sh
```

### Real output

```bash
$ ./sysinfo.sh
==============================================
           SYSTEM INFORMATION REPORT
==============================================
Current date : Mon Sep  7 01:02:20 AM IST 2026
Hostname     : Pottu-Lappy
Current user : utkuputku
Kernel       : 7.0.0-30-generic
Uptime       : up 12 minutes

----- Disk Usage (df -h) -----
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p5   55G   36G   19G  66% /
efivarfs        268K  170K   93K  65% /sys/firmware/efi/efivars
/dev/nvme0n1p1  196M   46M  151M  24% /boot/efi
/dev/nvme0n1p7  274G  230G   30G  89% /home

----- Memory Usage (free -h) -----
               total        used        free      shared  buff/cache   available
Mem:            10Gi       5.7Gi       252Mi       251Mi       5.5Gi       5.2Gi
Swap:          7.5Gi       636Ki       7.5Gi

----- Running Processes (top 10 by CPU) -----
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
utkuput+    7268 69.0  4.5 55609776 525756 ?     Sl   00:52   6:58 /opt/google/chrome/chrome
utkuput+   14915 33.8  2.0 1518725736 233036 ?   Sl   01:00   0:36 /opt/google/chrome/chrome --type=
utkuput+    9038 27.7  3.4 1519068744 397368 ?   Sl   00:52   2:37 /opt/google/chrome/chrome --type=
utkuput+   10482 26.9  3.9 1518748836 450364 ?   Sl   00:55   1:44 /opt/google/chrome/chrome --type=
utkuput+    7312 23.0  3.2 55901888 371216 ?     Sl   00:52   2:19 /opt/google/chrome/chrome --type=
utkuput+    5732 15.7  3.3 7068760 390548 ?      Ssl  00:52   1:36 /usr/bin/gnome-shell --mode=ubunt
utkuput+   16986 12.5  0.0  11264  4720 ?        Ss   01:02   0:00 /usr/bin/zsh -c source /home/utku
utkuput+   16962 11.5  0.8 1520588132 101332 ?   Sl   01:02   0:00 /opt/google/chrome/chrome --type=
avahi       1685 10.8  0.0  11372  9368 ?        Ss   00:50   1:19 avahi-daemon: running [Pottu-Lapp

Enter a name for your report directory: sysreport

Process list saved to sysreport/testProcess.txt
Lines written: 449
```

### Verifying the file that was created

```bash
$ ls -l sysreport/
total 68
-rw-rw-r-- 1 utkuputku utkuputku 67810 Sep  7 01:02 testProcess.txt

$ head -n 8 sysreport/testProcess.txt
Process snapshot taken on Mon Sep  7 01:02:20 AM IST 2026
Host: Pottu-Lappy   User: utkuputku

USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.2  0.1  26696 16220 ?        Ss   00:50   0:02 /usr/lib/systemd/systemd --switched-root --system --deserialize=52 splash
root           2  0.0  0.0      0     0 ?        S    00:50   0:00 [kthreadd]
root           3  0.0  0.0      0     0 ?        S    00:50   0:00 [pool_workqueue_release]
root           4  0.0  0.0      0     0 ?        I<   00:50   0:00 [kworker/R-rcu_gp]

$ wc -l sysreport/testProcess.txt
449 sysreport/testProcess.txt
```

The first two lines came from the `>` redirection (the header block), and the remaining 447 from the `>>` append of `ps aux`.

### Edge case: empty input

```bash
$ ./sysinfo.sh
Enter a name for your report directory:            # just pressed Enter

No name given - using default: sysreport
```

### Requirements checklist

| Requirement | Where it is satisfied |
|---|---|
| Prints current date | `current_date=$(date)` → `echo "Current date : $current_date"` |
| Prints hostname | `host_name=$(hostname)` |
| Prints username | `current_user=$(whoami)` |
| Prints disk usage | `df -h --exclude-type=tmpfs --exclude-type=devtmpfs` |
| Prints running processes | `ps aux --sort=-%cpu \| head -n 10 \| cut -c 1-100` |
| Uses variables | `current_date`, `host_name`, `current_user`, `kernel_version`, `up_time`, `dir_name`, `report_file` |
| Takes user input | `read -rp "Enter a name for your report directory: " dir_name` |
| Creates a directory | `mkdir -p "$dir_name"` |
| Creates a file | `touch "$report_file"` |
| Output redirection | `{ ... } > "$report_file"` then `ps aux >> "$report_file"` |

Full log: [`outputs/02-sysinfo-run.txt`](outputs/02-sysinfo-run.txt)

---

**Previous:** [Linux Fundamentals](../Linux%20Fundamentals/README.md) · **Next:** [Git / GitHub](../Git%20and%20GitHub/README.md) · [Back to index](../README.md)

*Utkarsh Bahuguna · 10161*
