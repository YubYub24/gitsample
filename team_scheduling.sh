#!/bin/bash

json_file="$(pwd)/data/data.json"

mkdir -p "$(dirname "$json_file")"


# Ensure JSON file exists
if [ ! -s "$json_file" ]; then
  echo "[]" > "$json_file"
fi

# Valid teams and shifts
valid_teams=("a1" "a2" "a3" "b1" "b2" "b3")
valid_shifts=("morning" "mid" "night")

# Function to validate exact match
is_valid() {
  local value="$1"
  shift
  local valid_list=("$@")
  for item in "${valid_list[@]}"; do
    [[ "$value" == "$item" ]] && return 0
  done
  return 1
}

# Append to JSON
add_to_json() {
  local name="$1"
  local shift="$2"
  local team="$3"
 local entry
  entry=$(jq -n \
    --arg name "$name" \
    --arg shift "$shift" \
    --arg team "$team" \
    '{name: $name, shift: $shift, team: $team}')

  jq ". += [$entry]" "$json_file" > tmp.json && mv tmp.json "$json_file"
}

# Print Output Table
print_table() {
  echo
 echo "|-------|------------|-----------------|"
  printf "| %-5s | %-10s | %-15s |\n" "Team" "Shift" "Employees"
  echo "|-------|------------|-----------------|"
  jq -r '
    group_by(.team + "-" + .shift) |
    .[] |
    {
      team: .[0].team,
      shift: .[0].shift,
      employees: (map(.name) | join(", "))
    } |
    [ .team, .shift, .employees ] |
    @tsv
  ' "$json_file" | while IFS=$'\t' read -r team shift employees; do
    printf "| %-5s | %-10s | %-15s |\n" "$team" "$shift" "$employees"
  done
  echo "|-------|------------|-----------------|"
}
# Main input loop
while true; do
  read -p "Enter Employee Name: " name

  if [[ "$name" == "print" ]]; then
    print_table
    exit 0
  fi

  # Prompt until valid shift
  while true; do
    read -p "Enter Shift (morning, mid, night): " shift
    if is_valid "$shift" "${valid_shifts[@]}"; then
      break
    else
      echo -e "\e[31mInvalid shift. Please enter: morning, mid, or night.\e[0m"
    fi
  done
  # Prompt until valid team
  while true; do
    read -p "Enter Team (a1, a2, a3, b1, b2, b3): " team
    if is_valid "$team" "${valid_teams[@]}"; then
      break
    else
      echo -e "\e[31mInvalid team. Please enter: a1, a2, a3, b1, b2, or b3.\e[0m"
    fi
  done

  # Count how many people already have that team-shift
  current_count=$(jq -r --arg team "$team" --arg shift "$shift" \
    '[.[] | select(.team == $team and .shift == $shift)] | length' "$json_file")
  if (( current_count >= 2 )); then
    echo "Maximum employees per shift in team $team reached. Exiting..."
    exit 1
  fi

  # Append new employee to JSON
  add_to_json "$name" "$shift" "$team"
done
