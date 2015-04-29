#!/bin/bash

. sc140.config

sleep_time=100 # longer than one play-through
too_long=$(( $dur * 5 / 4 ))

rm $alive

sleep 60 # git it time to start

while true
    do

        if [ -f $playing ] ; then
            # see if we've been playing too long
            last_played_a_new_sound=$(( $(date +%s) - $(date +%s -r $playing) ))
            if [ $last_played_a_new_sound -gt $too_long ] ; then
                 if [ -f $playing ] ; then # double check
                    echo "we're stuck playing one thing for too long"
                    kill $1
                    exit 0
                fi
            fi
        fi


        if [ ! -f $alive ]; then
            echo "File not found! - scweets has not checked in and must be hung"
            kill $1
            exit 0
        else

            rm $alive
        fi

        sleep $sleep_time
        sleep_time=300
        # the first trip through the loop is fast to catch start-up errors

done
