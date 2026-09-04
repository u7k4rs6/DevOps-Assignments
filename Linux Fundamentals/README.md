# Linux Fundamentals Assignment

**Name:** Utkarsh Bahuguna &nbsp;&nbsp;**Enrollment Number:** 10161

> Every command output in this file was captured on the machine described below.
> Raw logs live in [`outputs/`](outputs/).

```
$ uname -a
Linux Pottu-Lappy 7.0.0-30-generic #30-Ubuntu SMP PREEMPT_DYNAMIC Fri Jul 31 18:22:54 UTC 2026 x86_64 GNU/Linux

$ lsb_release -a
Distributor ID:	Ubuntu
Description:	Ubuntu 26.04 LTS
Release:	26.04
Codename:	resolute
```

---

## Task 1: Soft Links vs Hard Links

### The concept

Every file on a Linux filesystem is really two things: an **inode** (the metadata + pointers to the actual data blocks) and one or more **directory entries** (names) pointing at that inode.

**A hard link is just another name for the same inode.** It is not a copy and not a pointer to a name - it is a second entry in a directory that references the identical inode number. The kernel keeps a **link count** on the inode; `rm` only decrements that count, and the data blocks are freed only when the count reaches 0.

- Cannot cross filesystems - inode numbers are only unique *within* one filesystem.
- Cannot link a directory - that would let you build cycles the filesystem tools cannot safely walk.
- Editing through either name changes the same data, because there is only one set of data blocks.
- Deleting the "original" name does not break anything; the other name still holds a reference.

**A soft link (symlink) is a tiny file of its own whose contents are a path string.** It has its own inode, its own link count, and a file type of `l`. Resolving it means the kernel reads that path and starts the lookup again.

- Works across filesystems, because it stores a path, not an inode number.
- Can point at a directory.
- If the target is deleted or moved, the symlink still exists but now points nowhere - it becomes **dangling**.

### Commands and real output

```bash
$ touch test.txt
$ ln test.txt ptrHard
$ ln -s test.txt ptrSoft
$ echo "original content" > test.txt

$ ls -li
total 8
1312 -rw-rw-r-- 2 utkuputku utkuputku 17 Sep  7 01:00 ptrHard
1313 lrwxrwxrwx 1 utkuputku utkuputku  8 Sep  7 01:00 ptrSoft -> test.txt
1312 -rw-rw-r-- 2 utkuputku utkuputku 17 Sep  7 01:00 test.txt
```

Read that listing carefully - it contains the whole answer:

| | inode (col 1) | type | link count (col 3) | size |
|---|---|---|---|---|
| `test.txt` | **1312** | `-` regular | **2** | 17 (the real content) |
| `ptrHard`  | **1312** | `-` regular | **2** | 17 (the same content) |
| `ptrSoft`  | 1313 | `l` symlink | 1 | 8 (`"test.txt"` is 8 characters) |

`test.txt` and `ptrHard` share inode **1312** and both show a link count of **2** - one inode, two names. `ptrSoft` has its own inode and its size is exactly the length of the path string it stores.

### Editing through one name changes the other

```bash
$ echo "edited via hard link" >> ptrHard
$ cat test.txt
original content
edited via hard link

$ stat -c "%n inode=%i links=%h size=%s" test.txt ptrHard ptrSoft
test.txt inode=1312 links=2 size=38
ptrHard inode=1312 links=2 size=38
ptrSoft inode=1313 links=1 size=8
```

Both names report the new size of 38 bytes, because both name the same inode.

### Deleting the original: the decisive test

```bash
$ rm test.txt
$ ls -li
total 4
1312 -rw-rw-r-- 1 utkuputku utkuputku 38 Sep  7 01:00 ptrHard
1313 lrwxrwxrwx 1 utkuputku utkuputku  8 Sep  7 01:00 ptrSoft -> test.txt

$ cat ptrHard        # still works
original content
edited via hard link

$ cat ptrSoft        # dangling
cat: ptrSoft: No such file or directory
```

Note the link count on `ptrHard` dropped from `2` to `1` - `rm` removed a *name*, not the data. The symlink is untouched as a file but now resolves to a path that no longer exists.

### Directories

```bash
$ ln /home/utkuputku ptrDirHard
ln: /home/utkuputku: hard link not allowed for directory

$ ln -s /home/utkuputku ptrDirSoft && ls -ld ptrDirSoft
lrwxrwxrwx 1 utkuputku utkuputku 15 Sep  7 01:00 ptrDirSoft -> /home/utkuputku
```

The kernel refuses the hard link outright; the symlink is fine.

### Summary

| | Hard link | Soft link |
|---|---|---|
| Inode | Same as target | Its own |
| What it stores | Nothing - it *is* a name for the inode | A path string |
| Across filesystems | No | Yes |
| To a directory | No | Yes |
| Original deleted | Still works | Broken / dangling |
| Size | Same as the file | Length of the path string |
| Command | `ln file link` | `ln -s file link` |

Full log: [`outputs/01-links.txt`](outputs/01-links.txt)

---

## Task 2: `adduser` vs `useradd`

### The distinction

`useradd` is a **low-level ELF binary** from the `shadow-utils` package. It exists on essentially every Linux distribution and does exactly what you tell it and nothing more: no home directory, no password, no prompts, unless you pass flags.

`adduser` on Debian/Ubuntu is a **Perl script wrapper** around `useradd`. It applies distro policy: picks a UID from the right range, creates the home directory, copies `/etc/skel`, adds supplemental groups, and interactively prompts for a password and GECOS fields.

The demonstration below was run inside a clean `ubuntu:24.04` container so that real users could be created without modifying the host system:

```bash
docker run --rm ubuntu:24.04 bash -c '...'
```

### `useradd`: the low-level binary

```bash
$ type -a useradd
useradd is /usr/sbin/useradd

$ file -b /usr/sbin/useradd
ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, ... stripped

$ useradd -m -d /home/john -s /bin/bash -c "John Doe" john

$ id john
uid=1001(john) gid=1001(john) groups=1001(john)

$ grep ^john /etc/passwd
john:x:1001:1001:John Doe:/home/john:/bin/bash

$ ls -ld /home/john
drwxr-x--- 2 john john 4096 Sep  6 19:31 /home/john
```

Flags used:

| Flag | Effect |
|---|---|
| `-m` | Create the home directory (**without this there is none - proven below**) |
| `-d` | Path of the home directory |
| `-s` | Login shell |
| `-c` | GECOS comment / full name |

### Proof that `useradd` does nothing by default

```bash
$ useradd bare
$ grep ^bare /etc/passwd
bare:x:1003:1003::/home/bare:/bin/sh
$ ls -ld /home/bare
ls: cannot access '/home/bare': No such file or directory
```

`/etc/passwd` *claims* a home of `/home/bare`, but the directory was never created, the GECOS field is empty, and the shell defaulted to `/bin/sh`. This is exactly the class of half-configured account that `adduser` exists to prevent.

### `adduser`: the policy wrapper

```bash
$ type -a adduser
adduser is /usr/sbin/adduser

$ file -b /usr/sbin/adduser
Perl script text executable

$ adduser --gecos "Test User" --disabled-password test
info: Adding user `test' ...
info: Selecting UID/GID from range 1000 to 59999 ...
info: Adding new group `test' (1002) ...
info: Adding new user `test' (1002) with group `test (1002)' ...
info: Creating home directory `/home/test' ...
info: Copying files from `/etc/skel' ...
info: Adding new user `test' to supplemental / extra groups `users' ...
info: Adding user `test' to group `users' ...

$ id test
uid=1002(test) gid=1002(test) groups=1002(test),100(users)

$ grep ^test /etc/passwd
test:x:1002:1002:Test User,,,:/home/test:/bin/bash

$ ls -A /home/test
.bash_logout
.bashrc
.profile
```

`file` settles the argument outright: **`useradd` is an ELF binary, `adduser` is a Perl script.**

Note the extra work `adduser` did that `useradd` did not: it selected the UID from the policy range, added the supplemental group `users` (`groups=1002(test),100(users)`), and copied the skeleton files.

```bash
$ ls -A /etc/skel
.bash_logout
.bashrc
.profile
```

Those are the three files that appeared in `/home/test`.

> Run non-interactively here with `--disabled-password --gecos` so it could execute unattended. Used normally, `adduser` prompts for a password and for Full Name / Room Number / Work Phone.

### Which is preferred on Ubuntu?

**For manual, day-to-day administration on Ubuntu: `adduser`.** It is the distro-sanctioned front end - it applies the correct UID range, creates and populates the home directory, sets permissions, and forces you to set a password. Hard to get wrong.

**For scripts and automation: `useradd`.** It is non-interactive by definition, has stable flags, and exists on every distribution, so the same provisioning script works on RHEL, Alpine and Debian alike. `adduser` is Debian-family only and its interactivity is a liability in a pipeline.

Full log: [`outputs/01-users.txt`](outputs/01-users.txt)

---

## Task 3: `journalctl`

`journalctl` queries **systemd's journal**: a structured, indexed, binary log store that replaces hunting through plain-text files in `/var/log`. Because entries are structured, you can filter by unit, priority, boot and time range instead of writing `grep` pipelines.

```bash
$ journalctl --version
systemd 259 (259.5-0ubuntu3.4)

$ journalctl --disk-usage
Archived and active journals take up 1.7G in the file system.
```

### Core commands

```bash
journalctl                       # whole journal, oldest first, paged
journalctl -f                    # follow live, like tail -f
journalctl -b                    # this boot only
journalctl -b -1                 # the previous boot (crash investigation)
journalctl -r                    # newest first
journalctl -n 20                 # last 20 lines
journalctl -u docker.service     # one unit
journalctl -u nginx -f           # follow one unit
journalctl -k                    # kernel messages only
journalctl -p err -b             # priority err and worse, this boot
journalctl --since "1 hour ago"
journalctl --since "2026-09-05 00:00:00" --until "2026-09-05 12:00:00"
journalctl --list-boots          # boot IDs you can pass to -b
journalctl --disk-usage
sudo journalctl --vacuum-time=7d # trim by age
sudo journalctl --vacuum-size=200M
```

Priority numbers for `-p`: `0` emerg, `1` alert, `2` crit, `3` err, `4` warning, `5` notice, `6` info, `7` debug. `-p err` means "err **and more severe**".

### Practice: logs for a specific service

```bash
$ journalctl -u docker.service -b --no-pager -n 10
Sep 07 00:50:16 Pottu-Lappy dockerd[3921]: level=info msg="Initializing buildkit"
Sep 07 00:50:16 Pottu-Lappy dockerd[3921]: level=info msg="Completed buildkit initialization"
Sep 07 00:50:16 Pottu-Lappy dockerd[3921]: level=info msg="Daemon has completed initialization"
Sep 07 00:50:16 Pottu-Lappy dockerd[3921]: level=info msg="API listen on /run/docker.sock"
Sep 07 00:50:16 Pottu-Lappy systemd[1]: Started docker.service - Docker Application Container Engine.
Sep 07 01:00:47 Pottu-Lappy dockerd[3921]: level=info msg="image pulled" remote="docker.io/library/ubuntu:24.04"
```

That last line is the `ubuntu:24.04` pull from Task 2 - the journal recorded this assignment being done.

```bash
$ systemctl status docker --no-pager | head -12
● docker.service - Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; preset: enabled)
     Active: active (running) since Mon 2026-09-07 00:50:16 IST; 11min ago
TriggeredBy: ● docker.socket
       Docs: https://docs.docker.com
   Main PID: 3921 (dockerd)
      Tasks: 48
     Memory: 140.8M (peak: 142.2M)
        CPU: 2.942s
```

### Filtering by priority: finding actual problems

```bash
$ journalctl -p err -b --no-pager -n 8
Sep 07 00:50:02 Pottu-Lappy kernel: ACPI BIOS Error (bug): Failure creating named object [\_SB.PC00.XHCI.RHUB.SS10._PLD], AE_ALREADY_EXISTS
Sep 07 00:50:07 Pottu-Lappy systemd[1]: sysinit.target: Found ordering cycle: systemd-backlight@backlight:nvidia_0.service/start after nvidia-persistenced.service/start ...
Sep 07 00:50:07 Pottu-Lappy systemd[1]: sysinit.target: Unable to break cycle starting with sysinit.target/start
Sep 07 00:50:09 Pottu-Lappy bluetoothd[1686]: Failed to set mode: Failed (0x03)
```

Four real defects on this laptop, surfaced by one flag - a firmware ACPI bug, a genuine systemd unit ordering cycle involving the NVIDIA services, and a Bluetooth mode failure.

### Kernel ring buffer and boot history

```bash
$ journalctl -k --no-pager -n 6
Sep 07 01:01:09 Pottu-Lappy kernel: docker0: port 1(vethb1694d2) entered disabled state
Sep 07 01:01:09 Pottu-Lappy kernel: veth517a74e: renamed from eth0
Sep 07 01:01:09 Pottu-Lappy kernel: vethb1694d2 (unregistering): left promiscuous mode

$ journalctl --list-boots --no-pager | tail -5
  -4 623d0f66d5854233a5116589961464cd Fri 2026-09-04 21:47:02 IST Sat 2026-09-05 04:02:36 IST
  -3 217a2f0be5d24a75a5665ffce5740348 Sat 2026-09-05 15:39:56 IST Sat 2026-09-05 19:32:12 IST
  -2 af4e58d7f5104bcfa6fbe5b5ba6d587d Sat 2026-09-05 22:51:35 IST Sun 2026-09-06 06:20:48 IST
  -1 87a453db0e8b49cbbf04d13a03a6aa72 Sun 2026-09-06 09:07:49 IST Sun 2026-09-06 17:24:01 IST
   0 f9022c5b9dc04d99b03696d110723a80 Mon 2026-09-07 00:50:02 IST Mon 2026-09-07 01:01:10 IST
```

The kernel lines are the veth pairs being torn down as the Task 2 container exited. `--list-boots` gives the indices used by `-b -1`, `-b -2` and so on.

> **Note on `journalctl -u ssh.service`:** this returned `-- No entries --` because `sshd` is not installed on this laptop. Rather than fabricate output, `docker.service` was used as the worked example instead.

Full log: [`outputs/01-journalctl.txt`](outputs/01-journalctl.txt)

---

## Task 4: Linux Command Cheat Sheet

```bash
# --- navigation and files ---
pwd                      # print working directory
ls                       # list files
ls -al                   # long listing, including hidden entries
cd testDir               # change directory
mkdir testDir            # create a directory
touch test.txt           # create an empty file / update timestamps
cat test.txt             # print a file
cp src dst               # copy
mv src dst               # move or rename
rm test.txt              # remove a file
rmdir testDir            # remove an empty directory
rm -r testDir            # remove a directory and its contents
chmod 755 test.txt       # set permissions (rwx r-x r-x)
chown user:group file    # change owner and group
ln -s target link        # symlink (Task 1)

# --- searching ---
grep "pattern" file      # search inside a file
grep -rn "pattern" .     # recursive, with line numbers
find . -name "*.txt"     # find by name
which command            # locate an executable on $PATH

# --- processes ---
ps aux                   # every running process
ps aux --sort=-%cpu      # sorted by CPU
top / htop               # live process monitor
kill PID                 # ask a process to terminate (SIGTERM)
kill -9 PID              # force kill (SIGKILL)

# --- system information ---
whoami                   # current user
hostname                 # system hostname
uname -a                 # kernel and architecture
lsb_release -a           # distribution and release
uptime                   # uptime and load average
date                     # current date and time
df -h                    # disk free, human readable
du -sh *                 # size of each entry in this directory
free -h                  # memory usage

# --- networking (see assignment 04) ---
ip addr / ip -br addr    # interfaces and addresses
ip route                 # routing table
ping google.com          # reachability
curl https://google.com  # HTTP request
ss -tulpn                # listening sockets

# --- logs and history (see Task 3) ---
journalctl -u nginx -f   # follow a unit's logs
tail -f /var/log/syslog  # follow a plain-text log
history                  # previously run commands
sudo su                  # switch to root
```

### Real output from this machine

```bash
$ pwd
/home/utkuputku/Desktop/Devops-ass

$ whoami
utkuputku

$ hostname
Pottu-Lappy

$ date
Mon Sep  7 01:01:34 AM IST 2026

$ uptime
 01:01:34 up 11 min,  1 user,  load average: 2.80, 2.49, 1.46

$ free -h
               total        used        free      shared  buff/cache   available
Mem:            10Gi       5.8Gi       177Mi       267Mi       5.5Gi       5.2Gi
Swap:          7.5Gi       612Ki       7.5Gi

$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p5   55G   36G   19G  66% /
/dev/nvme0n1p1  196M   46M  151M  24% /boot/efi
/dev/nvme0n1p7  274G  230G   30G  89% /home

$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp7s0           DOWN
wlp0s20f3        UP             100.128.173.247/20 fe80::7390:1f2e:90f0:eef3/64
docker0          DOWN           172.17.0.1/16 fe80::f8c8:69ff:fe1a:a907/64

$ ping -c 3 google.com
PING google.com (142.250.134.113) 56(84) bytes of data.
64 bytes from fx-in-f113.1e100.net (142.250.134.113): icmp_seq=1 ttl=115 time=15.1 ms
64 bytes from fx-in-f113.1e100.net (142.250.134.113): icmp_seq=2 ttl=115 time=69.5 ms
64 bytes from fx-in-f113.1e100.net (142.250.134.113): icmp_seq=3 ttl=115 time=26.9 ms

--- google.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 15.092/37.178/69.548/23.390 ms

$ curl -sI https://google.com | head -2
HTTP/2 301
location: https://www.google.com/
```

Full log: [`outputs/01-cheatsheet.txt`](outputs/01-cheatsheet.txt)

---

**Next:** [Shell Scripting](../Shell%20Scripting/README.md) · [Back to index](../README.md)

*Utkarsh Bahuguna · 10161*
