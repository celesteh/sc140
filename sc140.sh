#!/bin/bash


# get the dir of this script
pushd `dirname $0` > /dev/null
program_dir=`pwd`
popd > /dev/null

# read our config file
. $program_dir/sc140.config

echo $tmp

#get the dir of SuperCollider
if [ -e /usr/local/bin/sclang ] 
    then
        sc_dir=/usr/local/bin
    else
        sc_dir=/usr/bin
fi

port=0
server=0

#are we on a raspberry pi
if [ -f /etc/rpi-issue ]
    then
        raspberry=1

        # let's setup a swap drive
        #if [ ! -e /swapfile ]
        #    then
        #        sudo dd if=/dev/zero of=/swapfile bs=1MB count=512 && sudo mkswap /swapfile
        #fi
        #sudo swapon /swapfile   

        port=$default_port   
  

    else
        raspberry=0
fi


#get rid of sc140 stuff in tmp
rm -rf $tmp

# and start afresh
mkdir $tmp
cd $program_dir
cp $data/rss.xml $rss #start with a pre-downloaded set of tweets in case of network delay

# this program starts with a lot of sleeping, in case you put it in your startup items.

sleep 20

#xfconf-query -c displays  -r -R -p / #fixes a display bug with xfce

# If you have a web-only authentication to get on the network, you can use lynx to
# replay old login sessions. See the man page for details.
# I chose to make a local copy of the login html page, rather than try to replay
# the redirection thing that webpages do with this sort of login

if [ $need_lynx -ne 0 ]
    then
        if [ $timeout -eq 0 ]
            then
                # do it once
                lynx $lynx_url -cmd_script=$lynx_log > /dev/null &
            else
                # do it when we time out
                (while true; do lynx $lynx_url -cmd_script=$lynx_log > /dev/null & sleep $timeout ; done )&
        fi
fi

#lynx $active_dur/seamus-login.html -cmd_script=$active_dur/login.log > /dev/null &

sleep 10


# let's try downloading some tweets
#python $program_dir/sctweet.py

sleep 1

# ok, let's try getting new tweets every 5 minutes from now on, but make it nice so it doesn't disrupt the rest of the program

if [ $raspberry -eq 0 ] 
    then 

         #also let's pre-copy over some tweets that ALWAYS crash the pi
       cd $program_dir
       cp $data/badtweets $badtweets
fi

        ( cd $program_dir ; sleep 90 ;  nice -n $niceness python $program_dir/sctweet.py && mv $working_rss $rss ; while true; do sleep $tweet_interval; nice -n $niceness python $program_dir/sctweet.py --subsequent && mv $working_rss $rss ; done ) &

#    else
#        # the pi can get them between playing them
#        ( sleep 60; sleep $tweet_interval; touch $should_fetch ) &
#        #also let's pre-copy over some tweets that ALWAYS crash the pi
#        cp $data/badtweets $badtweets
#fi

source $program_dir/jack_script.sh 

sleep 2

while true
    do
 
        #lynx $active_dur/seamus-login.html -cmd_script=$active_dur/login.log > /dev/null &

        touch $alive

        #sleep 1

        killall scsynth
        sleep 2

        if [ $raspberry -ne 0 ]
            then
                
            	$sc_dir/scsynth -i 0 -o 2 -u $port &
                server=$!
                sleep 1
                # is the server running?
                if kill -0 $server  2> /dev/null
                    then
                        #all good
                        echo "started"
                    else
                        # try again
                        
                        sleep 5
                        port=$(( $port + 1 ))                        
                	    $sc_dir/scsynth -i 0 -o 2 -u $port &
                        server=$!
                        
                        sleep 1
                        # is the server running?
                        if kill -0 $server  2> /dev/null
                            then
                                #all good
                                echo "started"
                            else
                                #sudo shutdown -r now
                                echo "fail"
                                #exit 1
                                sudo shutdown -r now
                        fi  
                fi
                sleep 5
                # is the server still running?
                if kill -0 $server  2> /dev/null
                    then
                        #all good
                        echo "still going"
                    else
                        sudo shutdown -r now
                fi
        fi

	    sleep 1	
        #echo $sc_dir/sclang $program_dir/sctweet.scd $tmp/sc140.config $raspberry

        $sc_dir/sclang $program_dir/sctweet.scd $port $program_dir/sc140.config $raspberry &
        pid=$!
        sleep 1
        cd $program_dir 
        $program_dir/keepAlive.sh $pid &
        alive_pid=$!

        #at the risk of getting silly
        $program_dir/keepAliveAlive.sh $alive_pid $pid $server &
        aliveAlive_pid=$!
        # it will die on its own within a minute of keepAlive dying
        #( wait $alive_pid ; kill $pid ) &

        wait $pid #wait for sclang to exit
        kill $alive_pid # this process no longer has the right pid for sclang
        kill $aliveAlive # it's won't live long on its own, but there's too much clutter

        # ok, did it die on a particular tweet?
        if [ -f $playing ] 
            then
                cat $playing >> $badtweets
                rm $playing
        fi

    
    
	sleep 1
        killall scsynth
        killall jackd
        jack_control stop
        # do we know the server's pid?
        if [ $server -ne 0 ]
            then
                kill $server
                sleep 1
                # is the server running?
                if kill -0 $1  2> /dev/null
                    then
                        kill -9 $server
                fi
        fi

    if [ $raspberry -ne 0 ]
        then
            # increment the port for the server
            port=$(( $port + 1 ))
            killall qjackctl.real # things that have spun out of control    	
            sleep 10 # needs a longer sleep because things take longer to settle
            # has the badtweets file somehow vanished?
            # or become truncated?
            if [ ! -f $badtweets ] || [ `du -k $badtweets | cut -f1` -lt `du -k $data/badtweets | cut -f1` ]
                then
                    cp $data/badtweets $badtweets
            fi

            #get rid of temporary synth files
            if [ -e $synthdef_dir ] 
                then
                    if [ -d $synthdef_dir ]
                        then
                            rm $synthdef_dir/temp*.scsyndef
                    fi
            fi


        else
            sleep 3 #shorter sleep for other computers
    fi
    

#     if [ -e $should_fetch ]
#        then
#            rm $should_fetch
#            nice -n -20 python $program_dir/sctweet.py && mv $working_rss $rss # do it asap
#            ( sleep $tweet_interval ; touch $should_fetch ) &
#        else
#        	sleep 3 #let jack settle
#    fi

	$program_dir/jack_script.sh 
	sleep 1
done
