#!/bin/sh
menu='fuzzel -d'
device=$(bluetoothctl devices Paired | cut -d ' ' -f 3- | $menu )
device_id=$(bluetoothctl devices | grep "$device" | awk {' print $2 '})
bluetoothctl connect $device_id
