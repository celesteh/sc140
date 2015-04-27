#!/bin/bash


# now setup the audio

if [ -f /etc/rpi-issue ]
    then
        raspberry=1
        export SC_JACK_DEFAULT_INPUTS="system"
        export SC_JACK_DEFAULT_OUTPUTS="system"
    else
        raspberry=0
fi

#pulseaudio --kill

# is the ultra attacked
if aplay -l | grep -qi ultra
  then
	echo ultra
	
	#adjust amplitude
	i=0
	j=0
	for i in $(seq 8); do
        	for j in $(seq 8); do
                	if [ "$i" != "$j" ]; then
                        	amixer -c Ultra set "DIn$i - Out$j" 0% > /dev/null
				#amixer -c Ultra set "DIn$i - Out$j" 100% > /dev/null
                	else
                        	amixer -c Ultra set "DIn$i - Out$j" 100% > /dev/null
                	fi
                	amixer -c Ultra set "AIn$i - Out$j" 0% > /dev/null
			#amixer -c Ultra set "AIn$i - Out$j" 100% > /dev/null
        	done
	done

	#for i in $(seq 4); do 
	#	amixer -c Ultra set "Effects return $i" 0% > /dev/null 
	#done	

	#start jack
    if [ $raspberry -ne 0 ]
        then
    	    ( jackd -T -d alsa -d hw:Ultra -r 44100 -i 0 -P || ( killall jackd ; sleep 10 ; jackd -T -d alsa -d hw:Ultra -r 44100 -i 0 -P || sudo shutdown -r now ) ) &
            sleep 10
    fi
    if [ $raspberry -eq 0 ]
        then
            jackd  -d alsa -d hw:Ultra -r 44100 &
   fi
  else
	#start jack with default hardware
	#jackd  -d alsa -d hw:0 -r 44100 &
    if [ $raspberry -ne 0 ]
        then
            #amixer cset numid=3 1
            #sleep 1
            killall jackd
            sleep 5
            ( jackd -T -p 32 -d alsa -d hw:0,0 -r 44100 -p 1024 -n3  -s -i 0 -P || ( killall jackd ; sleep 10 ; jackd -T -p 32 -d alsa -d hw:0,0 -r 44100 -p 1024 -n3  -s -i 0 -P || sudo shutdown -r now )) &
    fi
    if [ $raspberry -eq 0  ]
        then
        	jackd -p32 -dalsa -dhw:0,0 -p1024 -n3 -s &
    fi
fi

sleep 2

# jack control
if [ $raspberry -eq 0 ]
    then
        qjackctl &
fi

sleep 1


