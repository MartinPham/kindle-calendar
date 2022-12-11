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
LOG_FILE=$PWD/output.log

if [[ -f "$PWD/DISABLE" ]]; then
    echo `date '+%Y-%m-%d_%H:%M:%S'`: Calendar Disabled > $LOG_FILE
else
    echo `date '+%Y-%m-%d_%H:%M:%S'`: Calendar Enabled > $LOG_FILE

    # Screen resolution
    SCREEN_WIDTH=600
    SCREEN_HEIGHT=800

    # Label sizes
    DAY_LABEL_SIZE=55
    DATE_LABEL_SIZE=130
    MONTHYEAR_LABEL_SIZE=45
    QUOTE_LABEL_SIZE=20

    # Timer
    START_DELAY_TIME=15
    INTERVAL_TIME=21600
    LOOP_DELAY_TIME=3

    # FBINK="/mnt/us/extensions/MRInstaller/bin/K5/bin/fbink"
    FBINK="fbink"
    FONT=$PWD/GoboldBold.ttf
    BACKGROUND=$PWD/background.png
    QUOTE_FONT=$PWD/AppleChancery.ttf
    QUOTES=$PWD/quotes.txt
    WEEKDAYS=$PWD/weekdays.txt
    MONTHS=$PWD/months.txt
    ORIGINAL_SCREEN_WIDTH=758
    ORIGINAL_SCREEN_HEIGHT=1024
    X_RATIO=$((SCREEN_WIDTH*100/ORIGINAL_SCREEN_WIDTH))
    Y_RATIO=$((SCREEN_HEIGHT*100/ORIGINAL_SCREEN_HEIGHT))

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

        ## Day background
        eips -d l=ff,w=$((672*X_RATIO/100)),h=$((408*Y_RATIO/100)) -x $((X_RATIO*43/100)) -y $((Y_RATIO*232/100))

        ## Month/year background
        eips -d l=7e,w=$((672*X_RATIO/100)),h=$((179*Y_RATIO/100)) -x $((X_RATIO*43/100)) -y $((Y_RATIO*640/100))

        # Day
        DAY=`sed "$(date +%u)q;d" $WEEKDAYS`
        $FBINK -C GRAYE -O -m -t regular=$FONT,size=$DAY_LABEL_SIZE,top=$((35*Y_RATIO/100)),format "$DAY"

        # Date
        $FBINK -C BLACK -O -m -t regular=$FONT,size=$DATE_LABEL_SIZE,top=$((240*Y_RATIO/100)),format $(date +%-d)
        
        # Moth/Year
        MONTH=`sed "$(date +%-m)q;d" $MONTHS`
        $FBINK -C GRAYE -O -m -t regular=$FONT,size=$MONTHYEAR_LABEL_SIZE,top=$((663*Y_RATIO/100)),format "$MONTH $(date +%Y)"

        # Quotes
        TOTAL_QUOTES=`wc -l < $QUOTES`
        RANDOM=`</dev/urandom sed 's/[^[:digit:]]\+//g' | head -n2 | tr -dc '0-9' | sed 's/[^0-9]*//g'`
        RANDOM=${RANDOM:0:10} || 0
        RANDOM=$((1$RANDOM % $TOTAL_QUOTES)) || 0
        
        QUOTE=`sed "${RANDOM}q;d" $QUOTES`

        $FBINK -C GRAYE -O -m -M -t regular=$QUOTE_FONT,size=$QUOTE_LABEL_SIZE,top=$((820*Y_RATIO/100)),left=$((43*X_RATIO/100)),right=$((43*X_RATIO/100)),bottom=$((5*Y_RATIO/100)),padding=BOTH,format "$QUOTE"

        # Set powersave mode
        echo powersave > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

        # Schedule next update
        rtcwake -d /dev/rtc1 -m no -s $INTERVAL_TIME
        echo "mem" > /sys/power/state

        echo `date '+%Y-%m-%d_%H:%M:%S'`: Sleeping >> $LOG_FILE

        # truncate log
        echo "$(tail -n 100 $LOG_FILE)" > $LOG_FILE

        sleep $LOOP_DELAY_TIME;
    done
fi
