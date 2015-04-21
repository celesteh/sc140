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

    else
        raspberry=0
fi


#get rid of sc140 stuff in tmp
rm -rf $tmp

# and start afresh
mkdir $tmp
# put the config file there so supercollider can find it
cd $program_dir
cp $program_dir/sc140.config $tmp
cp $data/rss.xml $rss #start with a pre-downloaded set of tweets in case of network delay

# this program starts with a lot of sleeping, in case you put it in your startup items.

sleep 20

#xfconf-query -c displays  -r -R -p / #fixes a display bug with xfce

# If you have a web-only authentication to get on the network, you can use lynx to
# replay old login sessions. See the man page for details.
# I chose to make a local copy of the login html page, rather than try to replay
# the redirection thing that webpages do with this sort of login

#lynx $active_dur/seamus-login.html -cmd_script=$active_dur/login.log > /dev/null &

sleep 10


# let's try downloading some tweets
#python $program_dir/sctweet.py

sleep 1

# ok, let's try getting new tweets every 5 minutes from now on, but make it nice so it doesn't disrupt the rest of the program

if [ $raspberry -eq 0] 
    then 
        ( cd $program_dir ; sleep 60 ;  while true; do sleep $tweet_interval; nice -n $niceness python $program_dir/sctweet.py ; mv $working_rss $rss ; done ) &
    else
        # the pi can get them between playing them
        ( sleep 60; sleep $tweet_interval; touch $should_fetch ) &
fi

source $program_dir/jack_script.sh 


sleep 2

while true
    do
        cp $program_dir/sc140.config $tmp #this is a line for debugging

        #lynx $active_dur/seamus-login.html -cmd_script=$active_dur/login.log > /dev/null &

        touch $alive

        #sleep 1

        killall scsynth
        sleep 2

        if [ $raspberry -ne 0 ]
            then
            	( $sc_dir/scsynth -u 57110 || sudo shutdown -r now ) &
        fi

	sleep 1	
        echo $sc_dir/sclang $program_dir/sctweet.scd $tmp/sc140.config $raspberry

        $sc_dir/sclang $program_dir/sctweet.scd $tmp/sc140.config $raspberry &
        pid=$!
        sleep 1
        cd $program_dir 
        $program_dir/keepAlive.sh $pid &
        alive_pid=$!

        #at the risk of getting silly
        $program_dir/keepAliveAlive.sh $alive_pid $pid &
        # it will die on its own within a minute of keepAlive dying
        #( wait $alive_pid ; kill $pid ) &

        wait $pid #wait for sclang to exit
        kill $alive_pid # this process no longer has the right pid for sclang

        # ok, did it die on a particular tweet?
        if [ -f $playing ] 
            then
                cat $playing >> $badtweets
        fi

    
    (
	sleep 1
        killall scsynth
        killall jackd

    if [ $raspberry -ne 0 ]
        then
            killall qjackctl.real # things that have spun out of control    	
    fi
    ) &

     if [ -e $should_fetch ]
        then
            rm $should_fetch
            nice -n -20 python $program_dir/sctweet.py  #get it done ASAP
            mv $working_rss $rss 
            ( sleep $tweet_interval ; touch $should_fetch ) &
        else
        	sleep 3 #let jack settle
    fi

	$program_dir/jack_script.sh 
	sleep 1
done
