#!/bin/bash

. sc140.config

keepAlive=$1
sclang=$2
server=$3

 # while:
    # keep alive is running 
    # AND
        # we don't know the server's pid
        # OR
        # the server is also running           
        
    while ( kill -0 $keepAlive  2> /dev/null )  &&  ( [[ $server -eq 0 ]] ||  kill -0 $server  2> /dev/null  )
                do
                    sleep 60
                    #echo "keptAlive"
                done
    # it's no longer alive
    echo "================================="
    echo "keepAlive (or the server) is dead"
    kill $sclang

    #if [[ $server -ne 0 ]]
    #    then
    #        kill $server
    #    fi

    sleep 2
    if  kill -0 $sclang  2> /dev/null 
        then
            echo "sclang didn't die"
            if [[ $server -ne 0 ]]
                then
                    kill $server
            fi
            sleep 0
            kill -9 $sclang
    fi

    sleep 2
    count=0
    while  kill -0 $sclang  2> /dev/null 
        do
            if [[ $count -gt $dur ]] && [ -f /etc/rpi-issue ]
                then # give it 90 tries
                    sudo shutdown -r now
            fi
            echo "kill everything"
            kill -9 $sclang
            if ( [[ $server -ne 0  ]] && kill -0 $server  2> /dev/null )
                then
                    kill -9 $server
            fi
            sleep 0
            killall jackd
            sleep 0
            kill $sclang
            sleep 1
            count=$(( $count + 1 ))
    done
