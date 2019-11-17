## What is this?

This github repository contains a simple shell script that can be used to log the capacity of your laptop battery. It relies on data that is made available by Linux under `/sys/class/power_supply/` and makes a timestamped copy of this data in a specified file every time the script is called (but only if the data has changed). Only data-logging, nothing else. But this gives quite interesting plots after a few years of running:

[![Plot of battery.log with gnuplot](battery_small.png)](battery_large.png)

A few things to note:
* This plot contains data (capacity and level) for two batteries, alternating between the two.
* The capacity decreases when the battery is used and less so when it is not being used (unsurprisingly).
* The calibration (slope of the capacity curve as function of time) is very different for the two batteries.
* The capacity of battery 2 increases abruptly after it is drained completely. This seems to have an impact on the calibration.
* (Only visible in the higher-resolution version.) The capacity of battery 1 suddenly decreases when it is fully drained.

## Installation.
Without any warrenties. In the following, `[PATH]` is the path to the script.

You only need to install the script to be run as a cron job. Run `crontab -e` and add the following line:
`*/2  * * * * [PATH]/battery_log.sh cron >/tmp/batterylog.log`
You're done! I.e. it will log data every 2 minutes when running (at most). **Remember** to adjust the path to where the data should be written in `battery_log.sh`. In the script, there's a line `FILE_LOG=...`. Here you must give the absolute path to the output, i.e. replace `/tmp/battery.log` with the path to a file in your home directory. (The redirect `>/tmp/batterylog.log` for the cronjob above is only for debugging and can be left out.)

If you want additional data points on start-up and shutdown, try the following.

### Ubuntu 14.04

For Ubuntu 14.04 also install in rc etc.:
In `/etc/rc.local` add line 
`source [PATH]/battery_log.sh startup`
In `/etc/rc0.d/K10batterymon` add link to `../init.d/85batterymonshutdown`
In `/etc/rc6.d/K10batterymon` add link to `../init.d/85batterymonshutdown`
Create a file `/etc/init.d/85batterymonshutdown` with the following content
```
#!/bin/bash
source [PATH]/battery_log.sh shutdown_initd
```
Create another file `/etc/pm/sleep.d/20_alex` with the following content
```
#!/bin/bash
source [PATH]/battery_log.sh $1
```

### Ubuntu 15.04+ / systemd
Create a file `/etc/systemd/system/batterylog.service` with the following content
```
[Unit]
Description=Battery logging service, (85)

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=[PATH]/battery_log.sh startup_service
ExecStop=[PATH]/battery_log.sh shutdown_service

[Install]
WantedBy=multi-user.target
```
Run `systemctl enable batterylog`.
Create another file `/lib/systemd/system-sleep/battery_log` 
```
#!/bin/bash
source [PATH]/battery_log.sh $1 $2
```
and make this executable (`chmod +x ...`).
