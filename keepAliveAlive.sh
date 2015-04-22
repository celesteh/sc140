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
        
