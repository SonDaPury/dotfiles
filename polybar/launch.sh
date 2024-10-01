polybar-msg cmd quit
killall -q polybar

# Launch bar1 and bar2
#echo "---" | tee -a /tmp/polybar1.log 
#polybar mybar 

#echo "Bars launched..."

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar  mybar & 
    #MONITOR=$m polybar mybar_right &
    #MONITOR=$m polybar clock &
    #MONITOR=$m polybar tray_bar &
  done
fi
