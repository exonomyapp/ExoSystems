#!/bin/bash
export DISPLAY=:0
export XAUTHORITY=/run/user/1000/gdm/Xauthority
WID=$(xdotool search --name "ExoTech Bridge" | head -n 1)
if [ -n "$WID" ]; then
    xdotool windowactivate --sync $WID
    sleep 0.5
    xdotool key Tab
    sleep 0.5
    xdotool key Return
else
    echo "ExoTech Bridge window not found"
fi
