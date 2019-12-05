#!/bin/bash
#
# Log battery status.
#
# (85)
#
# $Id: battery_log.sh 3327 2019-12-05 21:20:33Z eis $


# log file
FILE_LOG=/tmp/battery.log # <- SPEFICY LOCATION FOR LOG FILE HERE

# which battery to log
BAT=BAT0

# temporary files
FILE_NEWLINE=/tmp/battery-new.log
FILE_LASTSTAMP=/tmp/battery-stamp.log
FILE_LASTLINE_CHECK=/tmp/battery-last-short.log
FILE_NEWLINE_CHECK=/tmp/battery-new-short.log
FILE_LOCK=/tmp/battery-lock

# locking mechanism
if [ -e $FILE_LOCK ]; then
  sleep 1
  if [ ! -e $FILE_LOCK ]; then
    # file gone => somebody else did our work already
    echo "locked, exit"
    exit
  fi
fi

touch $FILE_LOCK

# collect data for new line
rm -f $FILE_NEWLINE
cat /sys/class/power_supply/$BAT/serial_number      | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/$BAT/energy_now         | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/$BAT/energy_full        | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/$BAT/energy_full_design | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/$BAT/status             | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/AC/online               | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/$BAT/power_now          | tr "\n" " " >>$FILE_NEWLINE
# ignore the following when checking if values changed
rm -f $FILE_NEWLINE_CHECK
cp $FILE_NEWLINE $FILE_NEWLINE_CHECK
cat /sys/class/power_supply/$BAT/voltage_now        | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/hwmon/hwmon0/temp1_input             | tr "\n" " " >>$FILE_NEWLINE
# 
echo $1 >>$FILE_NEWLINE
echo $1 >>$FILE_NEWLINE_CHECK 

# compute time difference
TIMEDIFF=0
if [ -e $FILE_LASTSTAMP ]; then
  TIMEDIFF=$((`date +"%s"`-`cat $FILE_LASTSTAMP`))
fi

# add line to log if different from last line or if 1800 seconds have passed
if ! diff -q $FILE_NEWLINE_CHECK $FILE_LASTLINE_CHECK >/dev/null || [ ! -e $FILE_LASTSTAMP ] || [ $TIMEDIFF -ge 1800 ]; then 
  TIMESTAMP=`date +"%s"`
  echo -n "$TIMESTAMP " >>$FILE_LOG
  cat $FILE_NEWLINE >>$FILE_LOG
  mv -f $FILE_NEWLINE_CHECK $FILE_LASTLINE_CHECK
  echo $TIMESTAMP >$FILE_LASTSTAMP
fi

# clean up
for file in $FILE_NEWLINE $FILE_LASTSTAMP $FILE_NEWLINE_CHECK $FILE_LOCK; do
  if [[ $file == /tmp/* ]]; then 
    rm -f $file
  fi
done
chmod a+w $FILE_LASTLINE_CHECK

