#!/usr/bin/env bash
# System utilization stats for tmux status bar: CPU, RAM, GPU (NVIDIA/AMD), Network.
# Outputs tmux-formatted string with Nerd Font icons and % utilization.
# Heavy utilization (>= THRESHOLD%) turns the icon red (#ff5f5f).

THRESHOLD=80
COLOR_NORMAL="#00d7ff"
COLOR_HEAVY="#ff5f5f"
COLOR_TEXT="#6a6a8a"

format_stat() {
    local icon="$1"
    local pct="$2"
    local icon_color="$COLOR_NORMAL"

    if [ -n "$pct" ] && [ "$pct" -ge "$THRESHOLD" ] 2>/dev/null; then
        icon_color="$COLOR_HEAVY"
    fi

    printf "#[fg=%s]%s #[fg=%s]%s%%" "$icon_color" "$icon" "$COLOR_TEXT" "${pct:-0}"
}

# ── CPU Utilization (%) ───────────────────────────────────────────────
get_cpu() {
    local cache="/tmp/tmux-cpu-stat"
    local cpu_line
    read -r cpu_line < /proc/stat
    # cpu user nice system idle iowait irq softirq steal
    local _ user nice sys idle iowait irq softirq steal _
    read -r _ user nice sys idle iowait irq softirq steal _ <<< "$cpu_line"

    local total=$((user + nice + sys + idle + iowait + irq + softirq + steal))
    local active=$((total - idle - iowait))

    local pct=0
    if [ -f "$cache" ]; then
        local prev_total prev_active
        read -r prev_total prev_active < "$cache"
        local diff_total=$((total - prev_total))
        local diff_active=$((active - prev_active))
        if [ "$diff_total" -gt 0 ]; then
            pct=$(( (diff_active * 100) / diff_total ))
        fi
    fi
    printf "%s %s\n" "$total" "$active" > "$cache"
    echo "$pct"
}

# ── RAM Utilization (%) ───────────────────────────────────────────────
get_ram() {
    awk '/MemTotal:/ {total=$2} /MemAvailable:/ {avail=$2} END {
        if (total > 0) printf "%d", ((total - avail) * 100) / total;
        else print 0;
    }' /proc/meminfo
}

# ── GPU Utilization (%) — NVIDIA & AMD Radeon ─────────────────────────
get_gpu() {
    # 1. NVIDIA via nvidia-smi
    if command -v nvidia-smi >/dev/null 2>&1; then
        local nv_util
        nv_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d '[:space:]')
        if [[ "$nv_util" =~ ^[0-9]+$ ]]; then
            echo "$nv_util"
            return 0
        fi
    fi

    # 2. AMD Radeon via sysfs (amdgpu driver)
    local card
    for card in /sys/class/drm/card*/device/gpu_busy_percent; do
        if [ -r "$card" ]; then
            local amd_util
            read -r amd_util < "$card"
            if [[ "$amd_util" =~ ^[0-9]+$ ]]; then
                echo "$amd_util"
                return 0
            fi
        fi
    done

    # 3. AMD Radeon via rocm-smi fallback
    if command -v rocm-smi >/dev/null 2>&1; then
        local rocm_util
        rocm_util=$(rocm-smi --showuse 2>/dev/null | awk -F: '/GPU use/ {gsub(/[^0-9]/,"",$2); print $2; exit}')
        if [[ "$rocm_util" =~ ^[0-9]+$ ]]; then
            echo "$rocm_util"
            return 0
        fi
    fi

    return 1
}

# ── Network Throughput (Down / Up in B/s, K/s, M/s) ───────────────────
get_net() {
    local iface
    iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
    [ -z "$iface" ] && iface=$(ls /sys/class/net 2>/dev/null | grep -v '^lo$' | head -n1)
    [ -z "$iface" ] && { echo "0 0"; return; }

    local rx_file="/sys/class/net/${iface}/statistics/rx_bytes"
    local tx_file="/sys/class/net/${iface}/statistics/tx_bytes"

    [ -r "$rx_file" ] && [ -r "$tx_file" ] || { echo "0 0"; return; }

    local rx tx now
    read -r rx < "$rx_file"
    read -r tx < "$tx_file"
    now=$(date +%s)

    local cache="/tmp/tmux-net-stat-${iface}"
    local rx_bps=0 tx_bps=0

    if [ -f "$cache" ]; then
        local prev_rx prev_tx prev_time
        read -r prev_rx prev_tx prev_time < "$cache"
        local dt=$((now - prev_time))
        local drx=$((rx - prev_rx))
        local dtx=$((tx - prev_tx))
        if [ "$dt" -gt 0 ]; then
            [ "$drx" -ge 0 ] && rx_bps=$((drx / dt))
            [ "$dtx" -ge 0 ] && tx_bps=$((dtx / dt))
        fi
    fi

    printf "%s %s %s\n" "$rx" "$tx" "$now" > "$cache"
    echo "$rx_bps $tx_bps"
}

format_rate() {
    local bps="$1"
    if [ "$bps" -ge 1048576 ]; then
        awk -v b="$bps" 'BEGIN {printf "%.1fM", b/1048576}'
    elif [ "$bps" -ge 1024 ]; then
        printf "%sK" "$((bps / 1024))"
    else
        printf "%sB" "$bps"
    fi
}

format_net() {
    local rx_bps="$1"
    local tx_bps="$2"
    local icon_color="$COLOR_NORMAL"

    # Heavy network threshold: >= 10 MB/s (10485760 B/s) combined
    if [ "$((rx_bps + tx_bps))" -ge 10485760 ] 2>/dev/null; then
        icon_color="$COLOR_HEAVY"
    fi

    printf "#[fg=%s]󰛳 #[fg=%s]↓%s ↑%s" \
        "$icon_color" "$COLOR_TEXT" "$(format_rate "$rx_bps")" "$(format_rate "$tx_bps")"
}

cpu_pct=$(get_cpu)
ram_pct=$(get_ram)
read -r net_rx_bps net_tx_bps <<< "$(get_net)"

out="$(format_stat "" "$cpu_pct") $(format_stat "" "$ram_pct")"

if gpu_pct=$(get_gpu); then
    out="$out $(format_stat "󰢮" "$gpu_pct")"
fi

out="$out $(format_net "$net_rx_bps" "$net_tx_bps")"

printf "%s" "$out"
