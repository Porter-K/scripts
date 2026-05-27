#!/bin/sh
key=$(ls ~/.ssh/ | grep -v pub | grep -v known_hosts | fuzzel -d)
ssh-add ~/.ssh/$key
