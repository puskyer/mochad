#!/bin/bash
#
# zonex.sh is a sample bridge between mochad and ZoneMinder. Modify it to suit
# your needs.
#
# zonex looks for X10 events from mochad. When it receives an alert from a
# DS10A door/window sensor, zonex turns lights on by sending commands to
# mochad. Next zonex sends a trigger to ZoneMinder to tell it to start
# recording.
#
# Here is what a DS10A event from mochad looks like.  03/15 12:00:35 Rx RFSEC
# Addr: BB:AA:00 Func: Contact_alert_max_DS10A
#
# My ZoneMinder cameras are set to Nodect which means no video motion
# detection.  The cameras are all triggered X10 sensors.
#
# You may need to modify zmtrigger.pl to disable serial port monitoring and
# enable TCP monitoring.
#
# The following is an excerpt from the ZoneMinder Wiki. It is here to make it
# easier to understand the trigger format sent to ZoneMinder.
#
# This (zmtrigger.pl) is an optional script that is a more generic solution to
# external triggering of alarms. It can handle external connections via either
# internet socket, unix socket or file/device interfaces. You can either use it
# ‘as is’ if you can interface with the existing format, or override
# connections and channels to customise it to your needs. The format of
# triggers used by zmtrigger.pl is as follows
# "<id>|<action>|<score>|<cause>|<text>|<showtext>" where
# 
#         * 'id' is the id number or name of the ZM monitor
# 
#         * 'action' is 'on', 'off', 'cancel' or ‘show’ where 'on' forces an
#         alarm condition on, 'off' forces an alarm condition off and 'cancel'
#         negates the previous 'on' or 'off'. The ‘show’ action merely updates
#         some auxiliary text which can optionally be displayed in the images
#         captured by the monitor. Ordinarily you would use 'on' and 'cancel',
#         'off' would tend to be used to suppress motion based events.
#         Additionally 'on' and 'off' can take an additional time offset, e.g.
#         on+20 which automatically 'cancel's the previous action after that
#         number of seconds.
# 
#         * 'score' is the score given to the alarm, usually to indicate it's
#         importance. For 'on' triggers it should be non-zero, otherwise it
#         should be zero.
# 
#         * 'cause' is a 32 char max string indicating the reason for, or
#         source of the alarm e.g. 'Relay 1 open'. This is saved in the ‘Cause’
#         field of the event. Ignored for 'off' or 'cancel' messages
# 
#         * 'text' is a 256 char max additional info field, which is saved in
#         the ‘Description’ field of an event. Ignored for 'off' or 'cancel'
#         messages.
# 
#         * 'showtext' is up to 32 characters of text that can be displayed in
#         the timestamp that is added to images. The ‘show’ action is designed
#         to update this text without affecting alarms but the text is updated,
#         if present, for any of the actions. This is designed to allow
#         external input to appear on the images captured, for instance
#         temperature or personnel identity etc. 
# 
# Note that multiple messages can be sent at once and should be LF or CRLF
# delimited. This script is not necessarily intended to be a solution in
# itself, but is intended to be used as ‘glue’ to help ZoneMinder interface
# with other systems. It will almost certainly require some customisation
# before you can make any use of it. If all you want to do is generate alarms
# from external sources then using the ZoneMinder::SharedMem perl module is
# likely to be easier. 

MOCHADHOST=192.168.1.254
MOCHADPORT=1099

ZMHOST=192.168.1.12
ZMPORT=6802

# Send a ZoneMinder trigger
zmtrigger() {
    echo "$@" >/dev/tcp/${ZMHOST}/${ZMPORT}
}

# Connect TCP socket to mochad on handle 6.
exec 6<>/dev/tcp/${MOCHADHOST}/${MOCHADPORT}

# Read X10 events from mochad
while read <&6
do
    # Show the line on standard output just for debugging.
    echo ${REPLY} >&1
    case ${REPLY} in
        *Rx\ RFSEC\ Addr:\ 6B:AA:00\ Func:\ Contact_alert_*DS10A)
            # Start recording on camera 2 for 60 seconds
            zmtrigger "5|on+10|255|Front Door Open|Front Door Open"
            # flite is a lightweight text-to-speech program
            # flite -t "Front door open"
            ;;
        *Rx\ RFSEC\ Addr:\ 6B:AA:00\ Func:\ Contact_normal_*DS10A)
            # Think of something useful to do when door closes
            # flite -t "Goodbye"
            ;;
    esac
done
