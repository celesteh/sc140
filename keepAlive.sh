#!/bin/bash


while true
    do


        if [ ! -f /tmp/stillAlive ]; then
            echo "File not found! - scweets has not checked in and must be hung"
            kill $1
            exit 0
        else

            rm /tmp/stillAlive
        fi

        sleep 300


done
