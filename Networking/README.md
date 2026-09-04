# Network Fundamentals Assignment

**Name:** Utkarsh Bahuguna &nbsp;&nbsp;**Enrollment Number:** 10161

## Task — Network Troubleshooting Script

**Script:** [`netcheck.sh`](netcheck.sh)

### Approach

The script walks the network stack **from the bottom up**, because that is the order in which you should actually debug a connectivity problem. There is no point testing DNS if the interface is down, and no point running a traceroute if the name never resolved to an address.

| Layer | Question | Command |
|---|---|---|
| 1–2 Link | Is there an interface, and is it UP? | `ip -br addr` |
| 3 Network | Is there a route out — a default gateway? | `ip route` |
| Naming | Does the name resolve to an address? | `nslookup`, `dig +short` |
| 3 Reachability | Do packets reach the host and come back? | `ping -c 4` |
| 3 Path | *Where* on the path do packets die? | `tracepath` / `traceroute` |
| 4 Local | What is listening on this machine? | `ss -tulpn` |
| 7 Application | Does the service actually answer HTTP? | `curl` with timing |

Every section is appended to a **timestamped report file**, so the evidence can be attached to a ticket rather than lost in scrollback.

### The script

```bash
#!/bin/bash
#
# netcheck.sh - Network Troubleshooting Report
# DevOps Assignment 04: Network Fundamentals
# Author: Utkarsh Bahuguna (10161)
#
# Walks the network stack from the bottom up - interface, route, DNS,
# reachability, path, local ports - and writes everything to a timestamped
# report file so the evidence can be attached to a ticket.

set -u

# ---------- Variables ----------
report_dir="net_reports"
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

# ---------- User input ----------
read -rp "Enter hostname or IP to troubleshoot (e.g. google.com): " target
[ -z "$target" ] && target="google.com" && echo "No target given - using default: $target"

# ---------- Report file ----------
mkdir -p "$report_dir"
report_file="$report_dir/netcheck_${target}_${timestamp}.txt"
touch "$report_file"

# section <title> <command...>  -> runs a command, headed and appended to the report
section() {
    local title="$1"; shift
    {
        echo "----- $title -----"
        "$@" 2>&1
        echo
    } >> "$report_file"
}

# ---------- Header ----------
{
    echo "===== NETWORK TROUBLESHOOT REPORT for $target ====="
    echo "Generated on : $(date)"
    echo "Run from     : $(hostname) as $(whoami)"
    echo
} > "$report_file"

# ---------- 1. Layer 1/2/3: interfaces ----------
section "Network Interfaces (ip addr)" ip -br addr

# ---------- 2. Layer 3: routing table / default gateway ----------
section "Routing Table (ip route)" ip route

# ---------- 3. Layer 7-ish: DNS resolution ----------
section "DNS Resolution (nslookup)" nslookup "$target"
section "DNS Resolution (dig +short)" dig +short "$target"

# ---------- 4. Reachability ----------
echo "----- Ping Test (4 packets) -----" >> "$report_file"
ping -c 4 "$target" >> "$report_file" 2>&1
ping_status=$?
echo >> "$report_file"

# ---------- 5. Path to the host ----------
# traceroute is not installed by default on Ubuntu 26.04; tracepath ships with
# iputils and needs no root, so prefer whichever exists.
if command -v traceroute >/dev/null 2>&1; then
    section "Traceroute" traceroute -m 12 "$target"
else
    section "Path to host (tracepath - traceroute not installed)" tracepath -m 12 "$target"
fi

# ---------- 6. Local listening ports ----------
section "Local Listening Ports (ss -tulpn)" ss -tulpn

# ---------- 7. Application-layer check ----------
section "HTTP(S) check (curl -sSI)" curl -sS -m 10 -o /dev/null \
    -w "http_code=%{http_code} dns=%{time_namelookup}s connect=%{time_connect}s total=%{time_total}s\n" \
    "https://$target"

# ---------- Summary ----------
{
    echo "----- Summary -----"
    if [ $ping_status -eq 0 ]; then
        echo "Result: $target is REACHABLE (ping exit code 0)."
    else
        echo "Result: $target is UNREACHABLE (ping exit code $ping_status)."
        echo "Check, in order: interface UP? default route present? DNS resolving? firewall?"
    fi
} | tee -a "$report_file"

echo
echo "Full report saved to: $report_file"
```

### Design notes

| Choice | Why |
|---|---|
| `section()` helper | Every check is "print a heading, run a command, append output". Writing that once removes a dozen repeated redirections and keeps the report format uniform. |
| `2>&1` inside `section` | A failing command's error message *is* the diagnostic information. Discarding stderr would throw away the most useful line. |
| `ping_status=$?` captured immediately | `$?` is overwritten by the very next command, so it must be saved on the line straight after the `ping`. |
| `tracepath` fallback | `traceroute` is **not installed by default on Ubuntu 26.04**. `tracepath` ships with `iputils`, needs no root, and answers the same question. The script picks whichever exists. |
| `dig +short` alongside `nslookup` | `nslookup` output is verbose; `+short` gives a clean list that is easy to eyeball. Two resolvers also distinguish "DNS is broken" from "this one tool is being odd". |
| `curl -w` timing | Splits total latency into DNS vs TCP connect vs total — which tells you whether slowness is a name-resolution problem or a network one. |
| `tee -a` for the summary | The verdict needs to appear both on screen and in the report file. |

### How to run

```bash
chmod +x netcheck.sh
./netcheck.sh
```

### Success case

```bash
$ ./netcheck.sh
Enter hostname or IP to troubleshoot (e.g. google.com): google.com
----- Summary -----
Result: google.com is REACHABLE (ping exit code 0).

Full report saved to: net_reports/netcheck_google.com_2026-09-07_01-02-52.txt
```

### The generated report

```
===== NETWORK TROUBLESHOOT REPORT for google.com =====
Generated on : Mon Sep  7 01:02:52 AM IST 2026
Run from     : Pottu-Lappy as utkuputku

----- Network Interfaces (ip addr) -----
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp7s0           DOWN
wlp0s20f3        UP             100.128.173.247/20 fe80::7390:1f2e:90f0:eef3/64
br-99311fb8c732  UP             172.18.0.1/16 fe80::e0b2:3fff:fe6a:a152/64
docker0          DOWN           172.17.0.1/16 fe80::f8c8:69ff:fe1a:a907/64
vethd7f9e65@if2  UP             fe80::50bd:a5ff:fe91:76ff/64
veth61dddb2@if2  UP             fe80::78b7:1bff:feb6:5852/64
veth9032307@if2  UP             fe80::446d:18ff:fe31:a806/64

----- Routing Table (ip route) -----
default via 100.128.160.1 dev wlp0s20f3 proto dhcp src 100.128.173.247 metric 600
100.128.160.0/20 dev wlp0s20f3 proto kernel scope link src 100.128.173.247 metric 600
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
172.18.0.0/16 dev br-99311fb8c732 proto kernel scope link src 172.18.0.1

----- DNS Resolution (nslookup) -----
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
Name:	google.com
Address: 142.250.134.101
Name:	google.com
Address: 142.250.134.113
Name:	google.com
Address: 142.250.134.138
...
Name:	google.com
Address: 2404:6800:4000:1006::64

----- DNS Resolution (dig +short) -----
142.250.134.139
142.250.134.100
142.250.134.101
142.250.134.138
142.250.134.113
142.250.134.102

----- Ping Test (4 packets) -----
PING google.com (142.250.134.102) 56(84) bytes of data.
64 bytes from fx-in-f102.1e100.net (142.250.134.102): icmp_seq=1 ttl=115 time=15.9 ms
64 bytes from fx-in-f102.1e100.net (142.250.134.102): icmp_seq=2 ttl=115 time=17.0 ms
64 bytes from fx-in-f102.1e100.net (142.250.134.102): icmp_seq=3 ttl=115 time=15.2 ms
64 bytes from fx-in-f102.1e100.net (142.250.134.102): icmp_seq=4 ttl=115 time=17.4 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms
rtt min/avg/max/mdev = 15.218/16.404/17.438/0.876 ms

----- Path to host (tracepath - traceroute not installed) -----
 1?: [LOCALHOST]                      pmtu 1500
 1:  wifi.height8tech.com                                 10.265ms
 1:  wifi.height8tech.com                                  6.798ms
 2:  114.79.130.29.dvois.com                              24.023ms
 3:  72.14.208.165                                        18.701ms
 4:  no reply
 5:  no reply
...
12:  no reply
     Too many hops: pmtu 1500
     Resume: pmtu 1500

----- Local Listening Ports (ss -tulpn) -----
Netid State  Recv-Q Send-Q  Local Address:Port  Peer Address:Port Process
udp   UNCONN 0      0       127.0.0.53%lo:53         0.0.0.0:*
tcp   LISTEN 0      4096        127.0.0.1:6379       0.0.0.0:*
tcp   LISTEN 0      4096        127.0.0.1:5432       0.0.0.0:*
tcp   LISTEN 0      4096    127.0.0.53%lo:53         0.0.0.0:*
tcp   LISTEN 0      151         127.0.0.1:3306       0.0.0.0:*
tcp   LISTEN 0      4096        127.0.0.1:8333       0.0.0.0:*
tcp   LISTEN 0      4096        127.0.0.1:631        0.0.0.0:*
tcp   LISTEN 0      511         127.0.0.1:39907      0.0.0.0:*    users:(("code",pid=7562,fd=53))

----- HTTP(S) check (curl -sSI) -----
http_code=301 dns=0.001786s connect=0.025577s total=0.153176s

----- Summary -----
Result: google.com is REACHABLE (ping exit code 0).
```

### Reading the report

- **Interfaces** — `wlp0s20f3` is UP with a DHCP address; `enp7s0` (ethernet) is DOWN because nothing is plugged in. That is normal, not a fault. The `veth*` and `br-*` interfaces are Docker's, from the containers in the Docker assignments.
- **Routing** — `default via 100.128.160.1 dev wlp0s20f3` is the line that matters. Without a default route, nothing off the local subnet is reachable, no matter how healthy DNS is.
- **DNS** — the resolver is `127.0.0.53`, which is `systemd-resolved`'s stub listener, not the real upstream server. Google returns six IPv4 and four IPv6 addresses, so the client picks one per connection.
- **Ping** — 0% loss, ~16 ms average, and `mdev` (jitter) under 1 ms: a healthy link.
- **tracepath** — hops 1–3 resolve (home router, then the ISP), then `no reply` from hop 4 onward. **This is not a fault.** Google's edge routers and most backbone routers deliberately do not answer the TTL-expired probes traceroute relies on. Since ping and curl both succeed, the path is fine; the intermediate hops are simply silent.
- **`ss -tulpn`** — everything is bound to `127.0.0.1`, so none of these services are exposed to the network. Worth confirming on any machine you care about.
- **curl timing** — DNS took 1.8 ms and the TCP connect 25 ms. If a site felt slow and `dns=` were 2 seconds, you would know instantly where to look.

### Failure case

```bash
$ ./netcheck.sh
Enter hostname or IP to troubleshoot (e.g. google.com): nosuchhost.invalid
----- Summary -----
Result: nosuchhost.invalid is UNREACHABLE (ping exit code 2).
Check, in order: interface UP? default route present? DNS resolving? firewall?

Full report saved to: net_reports/netcheck_nosuchhost.invalid_2026-09-07_01-03-31.txt
```

The relevant sections of that report:

```
----- DNS Resolution (nslookup) -----
Server:		127.0.0.53
Address:	127.0.0.53#53

** server can't find nosuchhost.invalid: NXDOMAIN

----- DNS Resolution (dig +short) -----
                                        <- empty: no records at all

----- Ping Test (4 packets) -----
ping: nosuchhost.invalid: Name or service not known

----- Path to host (tracepath) -----
                                        <- nothing to trace
```

**The diagnosis is unambiguous.** `NXDOMAIN` means the DNS server authoritatively answered "that name does not exist". Ping never sent a single packet — it failed at name resolution, before any networking happened. The interfaces and routing table in the same report are healthy, which rules out the link and the gateway.

So the fault is at the **naming layer**, not the network: a typo, a missing DNS record, or the wrong search domain. Compare that with a report where DNS resolves fine but ping shows 100% packet loss — that would point at a firewall or a routing problem instead. Collecting all the layers in one report is what makes the difference visible.

### Exit codes

| `ping` exit code | Meaning |
|---|---|
| `0` | Host replied |
| `1` | Name resolved, but no reply (firewall, host down, ICMP blocked) |
| `2` | Other error — **including DNS failure**, as seen above |

The script branches on this to produce its verdict.

Full logs: [`outputs/04-netcheck-run.txt`](outputs/04-netcheck-run.txt) · [`outputs/04-netcheck-fail.txt`](outputs/04-netcheck-fail.txt)

---

**Previous:** [Git / GitHub](../Git%20and%20GitHub/README.md) · **Next:** [Docker Fundamentals](../Docker%20Fundamentals/README.md) · [Back to index](../README.md)

*Utkarsh Bahuguna · 10161*
