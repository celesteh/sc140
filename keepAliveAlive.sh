#!/bin/bash

. sc140.config

        
            while  kill -0 $1  2> /dev/null
                do
                    sleep 60
                    #echo "keptAlive"
                done
            # it's no longer alive
            echo "=========================="
            echo "keepAlive is dead"
            kill $2
        
