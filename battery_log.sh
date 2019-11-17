#!/bin/bash
#
# Log battery status.
#
# (85)
#
# $Id: battery_log.sh 3001 2018-09-08 17:05:22Z eis $


# config
FILE_LOG=/tmp/battery.log
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
cat /sys/class/power_supply/BAT0/serial_number      | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/BAT0/energy_now         | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/BAT0/energy_full        | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/BAT0/energy_full_design | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/BAT0/status             | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/AC/online               | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/power_supply/BAT0/power_now          | tr "\n" " " >>$FILE_NEWLINE
rm -f $FILE_NEWLINE_CHECK
cp $FILE_NEWLINE $FILE_NEWLINE_CHECK
cat /sys/class/power_supply/BAT0/voltage_now        | tr "\n" " " >>$FILE_NEWLINE
cat /sys/class/hwmon/hwmon0/temp1_input             | tr "\n" " " >>$FILE_NEWLINE
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

