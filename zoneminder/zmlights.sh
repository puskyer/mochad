#!/bin/bash
#
# Turn lights on when ZM starts recording an event and turn off when ZM stops.
# Or do whatever such as trigger sirens, blink lights, text-to-speech, etc.
#
# Monitor output from zmtrigger.pl. When ZM starts recording an event
# zmtrigger.pl outputs a line like this where the first parameter is the
# camera number.
# 2|on|1300323788|298
#
# When ZM stops recording an event zmtrigger.pl outputs a line like this.
# 2|off|1300323801|298
#
# The following table shows the 5 sample ZM cameras and corresponding 
# X10 commands to control lights. mochad is used in this example to turn 
# lights on/off but heyu or br or any other command line program.
#
# Location Cam  Command
# Garage    1   pl b2
# Kitchen   2   pl b1
# Test      3
# Living    4   pl b1
# Front Dr  5   pl b1
# 
LIGHT[1]="pl b2"
LIGHT[2]="pl b1"
LIGHT[3]=""
LIGHT[4]="pl b1"
LIGHT[5]="pl b1"

# mochad listens on this host and port
MOCHADHOST=192.168.1.254
MOCHADPORT=1099

# zmtrigger.pl listens on this host and port
ZMHOST=192.168.1.12
ZMPORT=6802

# Connect TCP socket to ZoneMinder zmtrigger.pl
exec 6<>/dev/tcp/${ZMHOST}/${ZMPORT}

# Read ZM events from zmtrigger.pl
while read <&6
do
    # Show the line on standard output just for debugging.
    # echo "${REPLY}" >&1
    case "${REPLY}" in
        *\|on\|*)
            CAM=${REPLY%%|*}        # extract camera number
            cmd=${LIGHT[${CAM}]}    # get the X10 command
            if [ "x${cmd}" != "x" ]
            then
                echo "${cmd} on" >/dev/tcp/${MOCHADHOST}/${MOCHADPORT}
            fi
            ;;
        *\|off\|*)
            CAM=${REPLY%%|*}        # extract camera number
            cmd=${LIGHT[${CAM}]}    # get the X10 command
            if [ "x${cmd}" != "x" ]
            then
                echo "${cmd} off" >/dev/tcp/${MOCHADHOST}/${MOCHADPORT}
            fi
            ;;
    esac
done
