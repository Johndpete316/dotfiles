#!/bin/bash
sleep 1  # Wait for desktop to load


code &
firefox &
alacritty &

sleep 2

# move windows to workspaces
wmctrl -r "Firefox" -t 0
wmctrl -r "Visual Studio Code" -t 1
wmctrl -r "alacritty" -t 2
