#!/bin/bash

. sc140.config

sleep_time=60

rm $alive

sleep $sleep_time

while true
    do


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
