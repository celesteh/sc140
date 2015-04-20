#!/bin/bash

. sc140.config

rm $alive

sleep 60

while true
    do


        if [ ! -f $alive ]; then
            echo "File not found! - scweets has not checked in and must be hung"
            kill $1
            exit 0
        else

            rm $alive
        fi

        sleep 300


done
