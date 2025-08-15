print_banner() {
    echo -e "${GREEN} ____             _                 _       _           "
    echo -e "|  _ \\  ___  ___| |__   ___   ___ | |_ ___| |__   __ _ "
    echo -e "| | | |/ _ \\/ __| '_ \\ / _ \\ / _ \\| __/ __| '_ \\ / _\` |"
    echo -e "| |_| |  __/ (__| | | | (_) | (_) | || (__| | | | (_| |"
    echo -e "|____/ \\___|\\___|_| |_|\\___/ \\___/\\__\\___|_| |_|\\__,_|${NC}"
    echo
}

health_bar() {
    local hp=$1
    local max=100
    local bar_len=20
    local filled=$((hp * bar_len / max))
    local empty=$((bar_len - filled))
    local bar=""
    for ((i=0;i<filled;i++)); do bar+="#"; done
    for ((i=0;i<empty;i++)); do bar+="-"; done
    echo "$bar"
}
USER_SIDE=""

choose_side() {
    if [[ -n "$1" ]]; then
        if [[ "$1" == "devops" || "$1" == "DevOps" ]]; then
            USER_SIDE="$PLAYER1"
        elif [[ "$1" == "dev" || "$1" == "developer" || "$1" == "Developer" ]]; then
            USER_SIDE="$PLAYER2"
        else
            USER_SIDE="$PLAYER1"
        fi
    else
        USER_SIDE="$PLAYER1"
    fi
}
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


PLAYER1="DevOps"
PLAYER2="Developer"
HP1=100
HP2=100

DEVOPS_ATTACKS=("Deploy Script" "Rollback" "Scale Up" "Monitor Alert" "Infra as Code")
DEVELOPER_ATTACKS=("Hotfix" "Refactor" "Feature Push" "Code Review" "Unit Test")


LOG_DIR="logs"
LOG_FILE="$LOG_DIR/battle_$(date +%Y%m%d_%H%M%S)_$$.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

log_event() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

rand() {
    echo $((RANDOM % ($2 - $1 + 1) + $1))
}

print_hp() {
    echo -e "${BLUE}$PLAYER1 HP: $HP1 [$(health_bar $HP1)]${NC}"
    echo -e "${YELLOW}$PLAYER2 HP: $HP2 [$(health_bar $HP2)]${NC}"
}

player_turn() {
    local attacker=$1
    local defender=$2
    local -n attacks=$3
    local -n hp_defender=$4

    local attack_idx=$(rand 0 $((${#attacks[@]} - 1)))
    local attack_name="${attacks[$attack_idx]}"
    local crit_roll=$(rand 1 10)
    local miss_roll=$(rand 1 10)
    local damage=$(rand 10 25)
    local msg=""
    if (( miss_roll == 1 )); then
        damage=0
        msg="${RED}Missed!${NC}"
    elif (( crit_roll == 10 )); then
        damage=$((damage * 2))
        msg="${GREEN}Critical Hit!${NC}"
    fi

    hp_defender=$((hp_defender - damage))
    if (( hp_defender < 0 )); then hp_defender=0; fi

    echo -e "$attacker uses $attack_name! $msg It deals $damage damage!"
    print_hp
    log_event "$attacker used $attack_name for $damage damage. $PLAYER1 HP: $HP1, $PLAYER2 HP: $HP2"
}




main() {
    # Check for argument (non-interactive), else prompt (interactive)
    print_banner
    choose_side "$1"
    echo -e "You are playing as: $USER_SIDE"
    echo "Battle Start!"
    print_hp
    log_event "Battle started between $PLAYER1 and $PLAYER2. User side: $USER_SIDE."
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

main "$1"
