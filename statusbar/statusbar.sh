while true; 
do 
        time=$(date +'%Y-%m-%d %X')
        current_brightness=$(cat /sys/class/backlight/intel_backlight/brightness)
        max_brightness=$(cat /sys/class/backlight/intel_backlight/max_brightness)
        brightness=$(($current_brightness*100/$max_brightness))
        bat=$(cat /sys/class/power_supply/BAT0/capacity)
        bat_status=$(cat /sys/class/power_supply/BAT0/status)
        mem=$(free -m | grep Mem | awk '{ print $3 }')
        printf "$time | $brightness%% | $bat%% $bat_status | $mem "
        sleep 1;
done;
