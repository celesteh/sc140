#!/bin/bash


# now setup the audio

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
	jackd  -d alsa -d hw:Ultra -r 44100 &
  else
	#start jack with default hardware
	#jackd  -d alsa -d hw:0 -r 44100 &
	jackd -p32 -dalsa -dhw:0,0 -p1024 -n3 -s &
fi

sleep 2

# jack control
qjackctl &

sleep 1


