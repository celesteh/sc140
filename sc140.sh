#!/bin/bash

# set this to the directory where you put all this stuff
program_dir=/home/pi/sc140

# this program starts with a lot of sleeping, in case you put it in your startup items.

sleep 20

#xfconf-query -c displays  -r -R -p / #fixes a display bug with xfce

# If you have a web-only authentication to get on the network, you can use lynx to
# replay old login sessions. See the man page for details.
# I chose to make a local copy of the login html page, rather than try to replay
# the redirection thing that webpages do with this sort of login

#lynx $active_dur/seamus-login.html -cmd_script=$active_dur/login.log > /dev/null &

sleep 10

$program_dir/jack_script.sh

cp $program_dir/rss.xml /tmp/ #start with a pre-downloaded set of tweets in case of network delay

sleep 2

while true
    do
        #lynx $active_dur/seamus-login.html -cmd_script=$active_dur/login.log > /dev/null &

        touch /tmp/stillAlive

        sleep 1

        killall scsynth
        sleep 1

	/usr/local/bin/scsynth -u 57110 &
	sleep 1	

        /usr/local/bin/sclang $program_dir/sctweet.scd &
        pid=$!
        sleep 1
        $program_dir/keepAlive.sh $pid &
        alive_pid=$!
        sleep 1
        wait $pid #wait for sclang to exit
        kill $alive_pid # this process no longer has the right pid for sclang

	sleep 1
        killall scsynth
	killall jackd

	sleep 1
	$program_dir/jack_script.sh
	sleep 1
done
