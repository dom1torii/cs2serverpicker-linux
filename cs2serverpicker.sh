#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo."
  exit 1
fi

echo -e "\e[?1049h\e[H"

# TUI library
source ./lib/bundle.bash

ipsfile="ips.txt"

fetchServers() {
  local json server_ips
  json=$(curl -s "https://api.steampowered.com/ISteamApps/GetSDRConfig/v1?appid=730")

  # Make a new json object using server name (desc) and server ips for convenience
  server_ips=$(echo "$json" | jq '
    .pops
    | to_entries
    | map(
        select(.value.relays != null and .value.desc != null)  # keep servers with relays & desc
        | {
            (.value.desc): (
              .value.relays
              | to_entries
              | map(.value.ipv4)
              | map(select(. != null))
            )
          }
      )
    | add
  ')

  echo "$server_ips"
}

createOptions() {
  local checked
  server_ips=$(fetchServers)

  mapfile -t options < <(echo "$server_ips" | jq -r 'keys[]')
  checked=$(checkbox "Select servers you want to play on (SPACE)" "${options[@]}")

  # convert options into server names
  selected=()
  for i in $checked; do
    selected+=("${options[i]}")
  done

  # output ips for those servers
  for server in "${options[@]}"; do
    [[ " ${selected[*]} " =~ " ${server} " ]] && continue
    echo "$server_ips" | jq -r --arg s "$server" '.[$s][]'
  done
}

startScreen() {
  local options option
  options=("Select servers" "Unblock all servers" "Block servers in the file (ips.txt)" "Quit")
  option=$(list "Choose one option" "${options[@]}")
  echo "${options[$option]}"
}

selectAgainScreen() {
  local confirmed
  confirmed=$(confirm "You already have servers selected. Do you wanna select them again?")
  echo "$confirmed"
}

blockFirewall() {
  chain="OUTPUT"
  custom_chain="GAME_BLOCKLIST"

  iptables -N "$custom_chain" 2>/dev/null || true
  iptables -C "$chain" -j "$custom_chain" 2>/dev/null || \
    iptables -A "$chain" -j "$custom_chain"

  while IFS= read -r ip; do
    [[ -z "$ip" || "$ip" =~ ^# ]] && continue

    iptables -C "$custom_chain" -d "$ip" -j DROP 2>/dev/null || \
      iptables -A "$custom_chain" -d "$ip" -j DROP
  done < "$ipsfile"
}

unblockFirewall() {
  chain="OUTPUT"
  custom_chain="GAME_BLOCKLIST"

  # delete chains
  iptables -D "$chain" -j "$custom_chain" 2>/dev/null || true
  iptables -F "$custom_chain" 2>/dev/null || true
  iptables -X "$custom_chain" 2>/dev/null || true
}

blockIps() {
  if [ ! -f "$ipsfile" ]; then
    touch "$ipsfile"
  fi
  : > "$ipsfile"
  createOptions >> "$ipsfile"

  unblockFirewall
  blockFirewall
}

unblockAll() {
  rm "$ipsfile"

  unblockFirewall
}

start_option=$(startScreen)

if [ ! -f "$ipsfile" ]; then

  if [ "$start_option" == "Select servers" ]; then
    blockIps
  elif [ "$start_option" == "Unblock all servers" ]; then
    unblockAll
  elif [ "$start_option" == "Block servers in the file (ips.txt)" ]; then
    blockFirewall
  else
    exit 0
  fi

else 

  if [ "$start_option" == "Select servers" ]; then
    select_again=$(selectAgainScreen)
    if [ "$select_again" = "1" ]; then
      blockIps
    else 
      exit 0
    fi
  elif [ "$start_option" == "Unblock all servers" ]; then
    unblockAll
  elif [ "$start_option" == "Block servers in the file (ips.txt)" ]; then
    blockFirewall
  else
    exit 0 
  fi 

fi

echo -e "\e[?1049l"
