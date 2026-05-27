#!/bin/sh
player=$(playerctl -l | fuzzel -d)
command=$(printf "play\npause\nplay-pause\nnext\nprevious\n" | fuzzel -d)
playerctl $command -p $player
