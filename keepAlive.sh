#!/bin/bash


while true
    do


        if [ ! -f /tmp/sc140/stillAlive ]; then
            echo "File not found! - scweets has not checked in and must be hung"
            kill $1
            exit 0
        else

            rm /tmp/sc140/stillAlive
        fi

        sleep 300


done
