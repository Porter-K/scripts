while true; 
do 
        time=$(date +'%Y-%m-%d %X')
        bat=$(cat /sys/class/power_supply/BAT0/capacity)
        bat_status=$(cat /sys/class/power_supply/BAT0/status)
        mem=$(free -m | grep Mem | awk '{ print $3 }')
        printf "$time | $bat%% $bat_status | $mem "
        sleep 1;
done;
