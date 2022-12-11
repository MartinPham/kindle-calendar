#!/bin/sh
# Mount as readwrite: mntroot rw
# Add startup script: /etc/upstart/calendar.conf
# start on started cmd
# stop on stopping cmd
# 
# export LANG LC_ALL
# 
# chdir /mnt/us/extensions/calendar 
# [ -f ./update.sh ] && exec ./update.sh 


PWD=$(pwd)
LOG_FILE=$PWD/log.txt

if [[ -f "$PWD/DISABLE" ]]; then
    echo "Calendar Disabled" > $LOG_FILE
else
    echo "Calendar Enabled" > $LOG_FILE

    SCREEN_WIDTH=758
    SCREEN_HEIGHT=1024
    START_DELAY_TIME=15
    INTERVAL_TIME=21600
    LOOP_DELAY_TIME=3


    FBINK="/mnt/us/extensions/MRInstaller/bin/K5/fbink"
    ORIGINAL_SCREEN_WIDTH=758
    ORIGINAL_SCREEN_HEIGHT=1024
    X_RATIO=$((SCREEN_WIDTH/ORIGINAL_SCREEN_WIDTH))
    Y_RATIO=$((SCREEN_HEIGHT/ORIGINAL_SCREEN_HEIGHT))
    FONT=$PWD/GoboldBold.ttf
    QUOTE_FONT=$PWD/AppleChancery.ttf
    QUOTES=$PWD/quotes.txt

    # Delay start
    sleep $START_DELAY_TIME

    # Disable screensaver
    lipc-set-prop com.lab126.powerd preventScreenSaver 1

    # Disable wireless
    lipc-set-prop com.lab126.cmd wirelessEnable 0

    # Disable useless services
    stop lab126_gui
    stop x
    # stop framework
    stop otaupd
    stop phd
    stop tmd
    stop todo
    stop mcsd
    stop archive
    stop dynconfig
    stop dpmd
    stop appmgrd
    stop stackdumpd
    # stop otaupd
    # stop phd
    # stop tmd
    # stop x
    # stop todo
    # stop mcsd

    # Render loop
    while true; do
        # Log battery level
        echo `date '+%Y-%m-%d_%H:%M:%S'`: Battery level: $(gasgauge-info -s | sed s/%//) >> $LOG_FILE

        # Clear screen
        eips -c
        
        # Fill background
        eips -d l=0,w=$SCREEN_WIDTH,h=$SCREEN_HEIGHT

        # Day background
        eips -d l=ff,w=$((672*X_RATIO)),h=$((408*Y_RATIO)) -x $((X_RATIO*43)) -y $((Y_RATIO*232))

        # Month/year background
        eips -d l=7e,w=$((672*X_RATIO)),h=$((179*Y_RATIO)) -x $((X_RATIO*43)) -y $((Y_RATIO*640))

        # Day
        $FBINK -C GRAYE -O -m -t regular=$FONT,size=$((55*X_RATIO)),top=$((35*Y_RATIO)),format  $(date +%A | tr a-z A-Z)

        # Date
        $FBINK -C BLACK -O -m -t regular=$FONT,size=$((130*X_RATIO)),top=$((240*Y_RATIO)),format  $(date +%d)
        
        # Moth/Year
        $FBINK -C GRAYE -O -m -t regular=$FONT,size=$((45*X_RATIO)),top=$((663*Y_RATIO)),format  "$(date +%b | tr a-z A-Z) $(date +%Y)"

        # Quotes
        TOTAL_QUOTES=`wc -l < $QUOTES`
        RANDOM=`</dev/urandom sed 's/[^[:digit:]]\+//g' | head -n2 | tr -dc '0-9' | sed 's/[^0-9]*//g'`
        RANDOM=${RANDOM:0:10} || 0
        RANDOM=$((1$RANDOM % $TOTAL_QUOTES)) || 0
        
        QUOTE=`sed "${RANDOM}q;d" $QUOTES`

        $FBINK -C GRAYE -O -m -t regular=$QUOTE_FONT,size=$((20*X_RATIO)),top=$((833*Y_RATIO)),left=$((43*X_RATIO)),right=$((43*X_RATIO)),bottom=$((100*Y_RATIO)),format "$QUOTE"

        # Set powersave mode
        echo powersave > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

        # Schedule next update
        rtcwake -d /dev/rtc1 -m no -s $INTERVAL_TIME
        echo "mem" > /sys/power/state

        echo `date '+%Y-%m-%d_%H:%M:%S'`: Sleeping >> $LOG_FILE

        sleep $LOOP_DELAY_TIME;
    done
fi
