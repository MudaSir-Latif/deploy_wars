# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
#!/usr/bin/env bash


# Player setup
PLAYER1="DevOps"
PLAYER2="Developer"
HP1=100
HP2=100

# Attack arrays
DEVOPS_ATTACKS=("Deploy Script" "Rollback" "Scale Up" "Monitor Alert" "Infra as Code")
DEVELOPER_ATTACKS=("Hotfix" "Refactor" "Feature Push" "Code Review" "Unit Test")


# Logging setup
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/battle_$(date +%Y%m%d_%H%M%S)_$$.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

# Log function
log_event() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Random number generator in range
rand() {
    echo $((RANDOM % ($2 - $1 + 1) + $1))
}

# Print HP
print_hp() {
    echo -e "${BLUE}$PLAYER1 HP: $HP1${NC} | ${YELLOW}$PLAYER2 HP: $HP2${NC}"
}

# Player turn
player_turn() {
    local attacker=$1
    local defender=$2
    local -n attacks=$3
    local -n hp_defender=$4

    local attack_idx=$(rand 0 $((${#attacks[@]} - 1)))
    local attack_name="${attacks[$attack_idx]}"
    local damage=$(rand 10 25)

    hp_defender=$((hp_defender - damage))
    if (( hp_defender < 0 )); then hp_defender=0; fi

    echo "$attacker uses $attack_name! It deals $damage damage!"
    print_hp
    log_event "$attacker used $attack_name for $damage damage. $PLAYER1 HP: $HP1, $PLAYER2 HP: $HP2"
}




# Main game loop
main() {
    echo "Battle Start!"
    print_hp
    log_event "Battle started between $PLAYER1 and $PLAYER2."
    turn=0
    while (( HP1 > 0 && HP2 > 0 )); do
        if (( turn % 2 == 0 )); then
            player_turn "$PLAYER1" "$PLAYER2" DEVOPS_ATTACKS HP2
        else
            player_turn "$PLAYER2" "$PLAYER1" DEVELOPER_ATTACKS HP1
        fi
        ((turn++))
        sleep 1
    done
    if (( HP1 <= 0 )); then
        echo -e "${YELLOW}$PLAYER2 wins!${NC}"
        log_event "$PLAYER2 wins!"
    else
        echo -e "${BLUE}$PLAYER1 wins!${NC}"
        log_event "$PLAYER1 wins!"
    fi
    echo "Battle log saved to $LOG_FILE"
}

main
