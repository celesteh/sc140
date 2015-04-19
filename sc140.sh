#!/bin/bash


# get the dir of this script
pushd `dirname $0` > /dev/null
program_dir=`pwd`
popd > /dev/null

# read our config file
. $program_dir/sc140.config


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
    else
        raspberry=0
fi


# this program starts with a lot of sleeping, in case you put it in your startup items.

sleep 20

#xfconf-query -c displays  -r -R -p / #fixes a display bug with xfce

# If you have a web-only authentication to get on the network, you can use lynx to
# replay old login sessions. See the man page for details.
# I chose to make a local copy of the login html page, rather than try to replay
# the redirection thing that webpages do with this sort of login

#lynx $active_dur/seamus-login.html -cmd_script=$active_dur/login.log > /dev/null &

sleep 10

cp $program_dir/rss.xml /tmp/ #start with a pre-downloaded set of tweets in case of network delay

# let's try downloading some tweets
#python $program_dir/sctweet.py

sleep 1

# ok, let's try getting new tweets every 5 minutes from now on, but make it nice so it doesn't disrupt the rest of the program
{ while true; sleep 300; do nice -n 10 python $program_dir/sctweet.py ;  done } &

$program_dir/jack_script.sh


sleep 2

while true
    do
        #lynx $active_dur/seamus-login.html -cmd_script=$active_dur/login.log > /dev/null &

        touch /tmp/stillAlive

        sleep 1

        killall scsynth
        sleep 1

        if [ $raspberry -ne 0 ]
            then
            	$sc_dir/scsynth -u 57110 &
        fi

	sleep 1	

        $sc_dir/sclang $program_dir/sctweet.scd $raspberry $dur $min_dur $chars_per_line &
        pid=$!
        sleep 1
        $program_dir/keepAlive.sh $pid &
        alive_pid=$!
        sleep 1
        wait $pid #wait for sclang to exit
        kill $alive_pid # this process no longer has the right pid for sclang

	sleep 1
        killall scsynth

    #if [ $raspberry ne 0 ]
    #    then
        	killall jackd
    #fi

	sleep 1
	$program_dir/jack_script.sh
	sleep 1
done
