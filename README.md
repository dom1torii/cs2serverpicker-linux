# CS2 Server Picker

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/e89d9c06-661b-4797-96c5-70e6d1dac024" />

## What it does

This tool allows you to choose servers you wanna play on by blocking relays (https://api.steampowered.com/ISteamApps/GetSDRConfig/v1?appid=730) that you don't want using [iptables](https://linux.die.net/man/8/iptables).

## Installation

Just clone the repository with `git clone https://github.com/dom1torii/cs2serverpicker-linux.git` into any directory.

## How to use 

- `cd` to the directory you just cloned.
- Run `chmod +x cs2serverpicker.sh` to make script executable.
- Run the script with `sudo ./cs2serverpicker.sh` (sudo is important to change firewall rules)

## Notes 

The script is not fully accurate and sometimes can send you to servers that are **routed** through the server you selected.

It's also possible that you won't find the server you selected.

If you have any ideas on how to fix any of these, make a pull request or message me on discord (.domitori)

## Credits

https://github.com/timo-reymann/bash-tui-toolkit (TUI library)
