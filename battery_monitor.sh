#!/bin/bash

# Configuration
HOME_ASSISTANT_URL="http://<ip-address>:8123"
HOME_ASSISTANT_TOKEN="<long-term-token-from-HA>"
SMART_PLUG_ENTITY="switch.<smartplugname-in-HA>"
NTFY_URL="ntfy.sh/<subscription-channel>"

# Script variables
LAST_PERCENTAGE=""
UNCHANGED_COUNT=0
CYCLE_COUNT=0

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to get battery info
get_battery_info() {
    upower -i $(upower -e | grep 'BAT') | grep -E "state|to\ full|percentage"
}

# Function to get switch state
get_switch_state() {
    local response=$(curl -s -X GET -H "Authorization: Bearer $HOME_ASSISTANT_TO
KEN" \
        "$HOME_ASSISTANT_URL/api/states/$SMART_PLUG_ENTITY" 2>&1)
    if [ $? -ne 0 ]; then
        log_message "Error getting switch state: $response"
        return 1
    fi
    echo "$response" | grep -o '"state":"[^"]*"' | cut -d'"' -f4
}

# Function to turn switch on
turn_switch_on() {
    log_message "Turning switch ON..."
    local response=$(curl -s -X POST \
        -H "Authorization: Bearer $HOME_ASSISTANT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"entity_id\": \"$SMART_PLUG_ENTITY\"}" \
        "$HOME_ASSISTANT_URL/api/services/switch/turn_on" 2>&1)
    if [ $? -eq 0 ]; then
        log_message "✓ Switch turned ON successfully"
    else
        log_message "✗ Failed to turn switch ON: $response"
    fi

    response=$(curl -s -d "MBP-SmartPlug ON ($(echo "$CURRENT_PERCENTAGE"))" "$N
TFY_URL" 2>&1)
    if [ $? -ne 0 ]; then
        log_message "Error sending notification: $response"
    fi
}

# Function to turn switch off
turn_switch_off() {
    log_message "Turning switch OFF..."
    local response=$(curl -s -X POST \
        -H "Authorization: Bearer $HOME_ASSISTANT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"entity_id\": \"$SMART_PLUG_ENTITY\"}" \
        "$HOME_ASSISTANT_URL/api/services/switch/turn_off" 2>&1)
    if [ $? -eq 0 ]; then
        log_message "✓ Switch turned OFF successfully"
    else
        log_message "✗ Failed to turn switch OFF: $response"
    fi

    response=$(curl -s -d "MBP-SmartPlug OFF ($(echo "$CURRENT_PERCENTAGE"))" "$
NTFY_URL" 2>&1)
    if [ $? -ne 0 ]; then
        log_message "Error sending notification: $response"
    fi
}

# Main monitoring function
main() {
    while true; do
        CYCLE_COUNT=$((CYCLE_COUNT + 1))
        CURRENT_INFO=$(get_battery_info)
        CURRENT_STATE=$(echo "$CURRENT_INFO" | grep "state" | awk '{print $2}')
        CURRENT_PERCENTAGE=$(echo "$CURRENT_INFO" | grep "percentage" | awk '{pr
int $2}' | tr -d '%')

        PLUG_STATE=$(get_switch_state)

        if [ $? -ne 0 ]; then
            log_message "Failed to get switch state. Retrying in 30 seconds..."
            sleep 30
            continue
        fi

        if [ $((CYCLE_COUNT % 2)) -eq 0 ]; then
            log_message "=== Every minute battery check ==="
            get_battery_info
            log_message "=== End minute check ==="
        fi

        log_message "Battery: ${CURRENT_PERCENTAGE}% (${CURRENT_STATE}) | Plug: 
${PLUG_STATE} | Unchanged: ${UNCHANGED_COUNT}/40"

        if [[ "$CURRENT_PERCENTAGE" == "$LAST_PERCENTAGE" ]]; then
            UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
        else
            UNCHANGED_COUNT=0
            LAST_PERCENTAGE="$CURRENT_PERCENTAGE"
        fi

        if (( $(echo "$CURRENT_PERCENTAGE <= 10" | bc -l) )) && [ "$CURRENT_STATE
" = "discharging" ] && [ "$PLUG_STATE" != "on" ]; then
            log_message "🔋 TRIGGER: Battery at ${CURRENT_PERCENTAGE}% and disch
arging!"
            turn_switch_on
        fi

        if [ "$UNCHANGED_COUNT" -ge 40 ] && [ "$PLUG_STATE" = "on" ]; then
            log_message "⏰ TRIGGER: Battery percentage unchanged for 20 minutes
!"
            turn_switch_off
            UNCHANGED_COUNT=0
        fi

        sleep 30
    done
}

# Handle cleanup on exit
cleanup() {
    log_message "Battery monitor stopped"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Check dependencies
if ! command -v upower &> /dev/null; then
    log_message "ERROR: upower not found. Install with: apt install upower"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    log_message "ERROR: curl not found. Install with: apt install curl"
    exit 1
fi

# Start monitoring
main
