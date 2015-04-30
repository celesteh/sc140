#!/bin/bash

. sc140.config

sleep_time=$(( $dur + 10 ))  # longer than one play-through
too_long=$(( $dur * 5 / 4 ))

rm $alive

sleep 60 # give it time to start

while true
    do
        if [ -f /etc/rpi-issue ]
            then
            #only if we're on a pi!
            if [ -f $playing ] ; then
                # see if we've been playing too long
                last_played_a_new_sound=$(( $(date +%s) - $(date +%s -r $playing) ))
                if [ $last_played_a_new_sound -gt $too_long ] ; then
                     if [ -f $playing ] ; then # double check
                        echo "we're stuck playing one thing for too long"
                        kill $1
                        #make extra sure
                        sleep 2
                        killall scsynth
                        sleep 0
                        killall jackd
                        sleep 1
                        killall jackd
                        exit 0
                    fi
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
        sleep_time=$(( $dur * 2 ))
        # the first trip through the loop is fast to catch start-up errors

done
