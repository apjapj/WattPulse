#!/bin/bash

# NAME: WattPulse
# VERSION: 3.6.0
# DESCRIPTION: Universal Power Diagnostic with Live Timer and Force-Exit logic.

VERSION="3.6.0"
LOG_FILE="wattpulse_$(date +%Y%m%d_%H%M%S).log"
SUMMARY_LOG="/tmp/wattpulse_events.log"
> "$SUMMARY_LOG"

# --- MATE Desktop Management ---
MATE_DIM_SETTING=false
if command -v gsettings &> /dev/null && gsettings list-schemas | grep -q "org.mate.power-manager"; then
    ORIG_MATE_DIM=$(gsettings get org.mate.power-manager idle-dim-ac)
    MATE_DIM_SETTING=true
    gsettings set org.mate.power-manager idle-dim-ac false
fi

# --- X11 Idle Management ---
if command -v xset &> /dev/null; then
    XSET_DATA=$(xset q | grep -A 1 "Screen Saver" | tail -n 1)
    ORIG_XSET_TIMEOUT=$(echo "$XSET_DATA" | awk '{print $2}')
    ORIG_XSET_CYCLE=$(echo "$XSET_DATA" | awk '{print $4}')
    XSET_AVAILABLE=true
    xset s off &>/dev/null
else
    XSET_AVAILABLE=false
fi

show_help() {
    cat << EOF
==========================================================================
                      WATTPULSE DIAGNOSTIC TOOL v$VERSION
==========================================================================
Usage: ./wattpulse.sh [OPTION]

OPTIONS:
  -h, --help      Show this help menu and hardware diagnostic tips.
  -v, --version   Show version.
  -l, --log-file  Run dashboard and save logs to $LOG_FILE.
  -s, --stress    Run a 30s CPU stress test (default duration).
  -t, --timer [s] Run the diagnostic for [s] seconds then auto-exit.

VOLTAGE "FLOOR" REFERENCE:
  Model                Typical Full | Critical Floor | Recommended
  ------------------------------------------------------------------------
  MBP 15" (2015)       ~12.0V - 12.6V |    ~10.8V     | 85W MagSafe 2
  MBP 13" (2015)       ~11.5V - 12.1V |    ~10.5V     | 60W MagSafe 2
  MBA 13" (2015)       ~8.0V  - 8.6V  |    ~7.2V      | 45W MagSafe 2

DIAGNOSTIC LOGIC:
  1. VOLTAGE SAG: Relative drop under load. Sag > 15% indicates a 
     failing power supply or battery capacity issue (Brownout).
  2. HANDSHAKE/CONNECTION: If Sag is low (< 5%) but logs show power
     state changes, check for dirty pins or a loose DC port.
==========================================================================
EOF
}

# --- Argument Handling ---
RUN_STRESS=false; SAVE_LOG=false; STRESS_FAILED_MISSING=false; TIMED_RUN=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -v|--version) echo "v$VERSION"; exit 0 ;;
        -s|--stress) RUN_STRESS=true ;;
        -l|--log-file) SAVE_LOG=true ;;
        -t|--timer) TIMED_RUN=true; RUN_DURATION="$2"; START_TIME=$(date +%s); shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

sudo -v || exit 1
clear

BAT_PATH=$(upower -e | grep battery | head -n 1)

cleanup() {
    tput rmcup
    [ "$MATE_DIM_SETTING" = true ] && gsettings set org.mate.power-manager idle-dim-ac "$ORIG_MATE_DIM"
    [ "$XSET_AVAILABLE" = true ] && [[ "$ORIG_XSET_TIMEOUT" =~ ^[0-9]+$ ]] && xset s "$ORIG_XSET_TIMEOUT" "$ORIG_XSET_CYCLE" &>/dev/null

    echo -e "\n=========================================================================="
    echo "                      SESSION SUMMARY & ANALYSIS"
    echo "=========================================================================="
    
    [ "$TIMED_RUN" = true ] && echo "  RUN TYPE:       Timed Auto-Exit ($RUN_DURATION seconds)."
    [ "$MATE_DIM_SETTING" = true ] && echo "  MATE SETUP:     Idle-dim-ac was suspended and restored ($ORIG_MATE_DIM)."
    [ "$XSET_AVAILABLE" = true ] && echo "  X11 SETUP:      Restored timeout $ORIG_XSET_TIMEOUT."

    if [ -n "$BAT_PATH" ]; then
        if (( $(echo "$MAX_VOLT > 0" | bc -l) )); then
            SAG_PERCENT=$(echo "scale=2; (($MAX_VOLT - $MIN_VOLT) / $MAX_VOLT) * 100" | bc -l)
        else
            SAG_PERCENT=0
        fi
        
        printf "  VOLTAGE RANGE:  Min: %-12s | Max: %-12s\n" "${MIN_VOLT}V" "${MAX_VOLT}V"
        printf "  CHARGE RANGE:   Min: %-12s | Max: %-12s (Sag: %s%%)\n" "${MIN_PERC}%" "${MAX_PERC}%" "$SAG_PERCENT"
        
        echo -e "\n  --- INTELLIGENT ANALYSIS ---"
        if (( $(echo "$SAG_PERCENT > 15.0" | bc -l) )); then
            echo "  [!] DIAGNOSIS: BROWNOUT / CAPACITY ISSUE"
        elif [ -s "$SUMMARY_LOG" ]; then
            echo "  [*] DIAGNOSIS: INTERMITTENT CONNECTION / HANDSHAKE"
            echo "      Note: All OS idle dimming was disabled. These events are LIKELY"
            echo "      genuine hardware power-loss disconnects."
        else
            echo "  [✓] DIAGNOSIS: SYSTEM HEALTHY"
        fi
    fi
    
    echo "--------------------------------------------------------------------------"
    if [ -s "$SUMMARY_LOG" ]; then
        echo "Recorded Journal Events (Since Start):"
        cat "$SUMMARY_LOG" | sort -u | sed 's/^/  /'
    fi
    echo "=========================================================================="
    exit 0
}
trap cleanup SIGINT SIGTERM

if [ "$RUN_STRESS" = true ]; then
    STRESS_TIME=${RUN_DURATION:-30}
    if ! command -v stress-ng &> /dev/null; then STRESS_FAILED_MISSING=true; RUN_STRESS=false;
    else stress-ng --cpu $(nproc) --timeout "${STRESS_TIME}s" --quiet & fi
fi

tput smcup; clear; tput cup 12 0
echo "--- LIVE POWER STREAM (Filtered & Clean Start) ---------------------------"

LOG_FILTER="battery\|acpi\|power\|under-voltage\|voltage\|backlight\|thermal"
(sudo journalctl -n 0 -f | grep -i --line-buffered "$LOG_FILTER") &
(sudo journalctl -n 0 -f | grep -i --line-buffered "$LOG_FILTER" >> "$SUMMARY_LOG") &

MIN_VOLT=999; MAX_VOLT=0; MIN_PERC=100; MAX_PERC=0
while true; do
    # Timer Check for Auto-Exit
    if [ "$TIMED_RUN" = true ]; then
        NOW=$(date +%s)
        ELAPSED=$((NOW - START_TIME))
        REMAINING=$((RUN_DURATION - ELAPSED))
        if [ "$REMAINING" -le 0 ]; then cleanup; fi
    fi

    tput sc; tput cup 0 0
    for i in {0..11}; do tput cup $i 0; tput el; done
    tput cup 0 0
    echo "=========================================================================="
    echo "                 WATTPULSE DIAGNOSTIC DASHBOARD v$VERSION"
    if [ "$TIMED_RUN" = true ]; then
        printf "  STATUS: [ TIMED RUN: %ss REMAINING ]\n" "$REMAINING"
    else
        echo "  STATUS: [ CONTINUOUS MONITORING ]"
    fi
    echo "=========================================================================="
    if [ -n "$BAT_PATH" ]; then
        DATA=$(upower -i "$BAT_PATH")
        CUR_VOLT=$(echo "$DATA" | grep "voltage" | awk '{print $2}' | sed 's/V//')
        CUR_PERC=$(echo "$DATA" | grep "percentage" | awk '{print $2}' | sed 's/%//')
        STATE=$(echo "$DATA" | grep "state" | awk '{print $2}')
        if [[ "$CUR_VOLT" =~ ^[0-9.]+$ ]]; then
            (( $(echo "$CUR_VOLT < $MIN_VOLT" | bc -l) )) && MIN_VOLT=$CUR_VOLT
            (( $(echo "$CUR_VOLT > $MAX_VOLT" | bc -l) )) && MAX_VOLT=$CUR_VOLT
        fi
        if [[ "$CUR_PERC" =~ ^[0-9.]+$ ]]; then
            (( $(echo "$CUR_PERC < $MIN_PERC" | bc -l) )) && MIN_PERC=$CUR_PERC
            (( $(echo "$CUR_PERC > $MAX_PERC" | bc -l) )) && MAX_PERC=$CUR_PERC
        fi
        printf "  %-12s %-18s\n" "POWER STATE:" "$STATE"
        printf "  %-12s %-18s (Min: %-14s | Max: %-14s)\n" "VOLTAGE:" "${CUR_VOLT}V" "${MIN_VOLT}V" "${MAX_VOLT}V"
        printf "  %-12s %-18s (Min: %-14s | Max: %-14s)\n" "CHARGE:" "${CUR_PERC}%" "${MIN_PERC}%" "${MAX_PERC}%"
    fi
    echo "--------------------------------------------------------------------------"
    tput rc; sleep 2
done
