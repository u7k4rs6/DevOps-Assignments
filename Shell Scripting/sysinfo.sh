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
