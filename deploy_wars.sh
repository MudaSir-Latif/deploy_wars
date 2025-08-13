#!/usr/bin/env bash
set -Eeuo pipefail

# Color handling
supports_color() {
  if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    local colors
    colors=$(tput colors || echo 0)
    [[ ${colors:-0} -ge 8 ]] && return 0
  fi
  return 1
}
if supports_color || [[ ${FORCE_COLOR:-} == "1" ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
fi

# Player setup
PLAYER1="DevOps"
PLAYER2="Developer"
HP1=100
HP2=100

# Attacks
DEVOPS_ATTACKS=("Deploy Script" "Rollback" "Scale Up" "Monitor Alert" "Infra as Code")
DEVELOPER_ATTACKS=("Hotfix" "Refactor" "Feature Push" "Code Review" "Unit Test")

# Logging
LOG_DIR="logs"
mkdir -p "$LOG_DIR" || { echo -e "${RED}Failed to create logs directory.${NC}" >&2; exit 1; }
LOG_FILE="$LOG_DIR/battle_$(date +%Y%m%d_%H%M%S)_$$.log"
: > "$LOG_FILE" || { echo -e "${RED}Cannot write to log file: $LOG_FILE${NC}" >&2; exit 1; }

log_event() {
  local msg="$1"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '[%s] %s\n' "$ts" "$msg" | tee -a "$LOG_FILE" >/dev/null
}

# Error handling
cleanup() {
  local status=$?
  if (( status != 0 )); then
    echo -e "${RED}An unexpected error occurred (exit $status). See $LOG_FILE for details.${NC}" >&2
    log_event "ERROR: Script exited unexpectedly with status $status."
  fi
}
trap cleanup EXIT

# Random number helper
rand_range() {
  local min=$1 max=$2
  if command -v shuf >/dev/null 2>&1; then
    shuf -i "$min"-"$max" -n 1
  elif command -v jot >/dev/null 2>&1; then
    jot -r 1 "$min" "$max"
  else
    local range=$((max - min + 1))
    echo $(( (RANDOM % range) + min ))
  fi
}

# UI
print_hp() {
  echo -e "${BLUE}$PLAYER1 HP: $HP1${NC} | ${YELLOW}$PLAYER2 HP: $HP2${NC}"
}
banner() {
  cat <<'BANNER'
 ____             _                 _       _                     
|  _ \  ___  _ __| | ___  _   _  __| | __ _| | ___  __ _ _ __ ___ 
| | | |/ _ \| '__| |/ _ \| | | |/ _` |/ _` | |/ _ \/ _` | '__/ _ \
| |_| | (_) | |  | | (_) | |_| | (_| | (_| | |  __/ (_| | | |  __/
|____/ \___/|_|  |_|\___/ \__,_|\__,_|\__,_|_|\___|\__,_|_|  \___|
BANNER
}
choose_side() {
  if [[ "${NO_PROMPT:-0}" == "1" ]]; then
    USER_SIDE="$PLAYER1"
    return
  fi
  echo "Choose your side:"
  echo "  1) $PLAYER1"
  echo "  2) $PLAYER2"
  read -rp "Enter 1 or 2: " choice || true
  case "${choice:-}" in
    1) USER_SIDE="$PLAYER1" ;;
    2) USER_SIDE="$PLAYER2" ;;
    *) echo -e "${YELLOW}Invalid choice. Defaulting to $PLAYER1.${NC}"; USER_SIDE="$PLAYER1" ;;
  esac
}

# Game mechanics
player_turn() {
  local attacker=$1
  local defender=$2
  local attack_array_name=$3
  local hp_attacker_name=$4
  local hp_defender_name=$5
  local color=$6

  # Safe nameref
  if ! declare -p "$attack_array_name" >/dev/null 2>&1; then
    log_event "ERROR: Attack array '$attack_array_name' not found."
    echo -e "${RED}Attack array '$attack_array_name' not found. Skipping turn.${NC}"
    return 1
  fi
  local -n attacks="$attack_array_name"
  local -n hp_attacker="$hp_attacker_name"
  local -n hp_defender="$hp_defender_name"

  local idx damage attack_name
  idx=$(rand_range 0 $(( ${#attacks[@]} - 1 )))
  attack_name="${attacks[$idx]}"
  damage=$(rand_range 10 25)

  hp_defender=$(( hp_defender - damage ))
  (( hp_defender < 0 )) && hp_defender=0

  echo -e "${color}${attacker} uses ${attack_name}! It deals ${damage} damage!${NC}"
  print_hp
  log_event "${attacker} used ${attack_name} for ${damage} damage. ${PLAYER1} HP: ${HP1}, ${PLAYER2} HP: ${HP2}"
}

main() {
  NO_PROMPT=0
  for arg in "$@"; do
    case "$arg" in
      --no-prompt) NO_PROMPT=1 ;;
      -h|--help) echo "Usage: $0 [--no-prompt]"; exit 0 ;;
    esac
  done
  [[ $NO_PROMPT -eq 1 ]] && export NO_PROMPT=1

  banner
  choose_side
  echo -e "${GREEN}Battle Start!${NC}"
  print_hp
  log_event "Battle started between ${PLAYER1} and ${PLAYER2}. User side: ${USER_SIDE}"

  local turn=0
  while (( HP1 > 0 && HP2 > 0 )); do
    if (( turn % 2 == 0 )); then
      player_turn "$PLAYER1" "$PLAYER2" DEVOPS_ATTACKS HP1 HP2 "$BLUE" || break
    else
      player_turn "$PLAYER2" "$PLAYER1" DEVELOPER_ATTACKS HP2 HP1 "$YELLOW" || break
    fi
    ((turn++))
    sleep 0.5
  done

  if (( HP1 <= 0 && HP2 <= 0 )); then
    echo -e "${YELLOW}It's a draw!${NC}"
    log_event "Result: Draw."
  elif (( HP1 <= 0 )); then
    echo -e "${YELLOW}${PLAYER2} wins!${NC}"
    log_event "Winner: ${PLAYER2}."
  else
    echo -e "${BLUE}${PLAYER1} wins!${NC}"
    log_event "Winner: ${PLAYER1}."
  fi

  echo -e "Battle log saved to ${LOG_FILE}"
}

main "$@"
