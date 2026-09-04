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
