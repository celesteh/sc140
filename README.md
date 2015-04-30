sc140
=====

Download and play SuperCollider Tweets

This requires SuperCollider, the XML SuperCollider Quark, Python. The tweepy python lib, Bash and may require lynx (see lynx-readme.md). It has been tested on Ubuntu studio and Raspbian and should run on OS X with minimal modification.

You will need to register as an app developer with Twitter in order to get API keys.
I recommend creating a twitter account specififcally for this program. When you run these programs, it will automatically discover and follow many #sc140 tweeters. If you are concerned it may have issed someone, you can also manually follow everyone currently followed by [@sc140Bot] (https://twitter.com/sc140Bot)

To install:

* Copy the SC140_Extensions folder to your SuperCollider Extensions.
* Start sclang and run the program: `Quarks.install("XML")`
* Put your Twitter API keys into data/oauth.dat
* If you do not need to start Jack, you will need to comment out jack_script.sh and/or modify it for your setup
* Make all the .sh files executable

To run:
Run the program sc140.sh


Run as an Installation
======================

* Put the SC140_Extnesions folder as a system extension, not just one for your own user.
* Change permissions on the folder holding the rest of the project and all of the sub files so they are readable by all users, but not writerable.
* Change permissions on on all the .sh files so they are also executable by all users, but not writerable.
* Create a new user account, specifically to to run the installation. Do not allow this user to administrate the computer.
* Set the new user to auto-login.
* Change the desktop background for the new user to solid black
* Add sc140.sh to the new user's programs that are invoked automatically on login
* If you would like to install this on a network that requires logging in via a webpage, see the lynx-readme


Run as an Installation on Raspbian Wheezy
=========================================

Because making extra users on Pi is a faff, I suggest setting this up and then taking an image of the SD card. If anything goes wrong, you can rewrite your card with the image.  If you do find an evil tweet, there is a file in data called badtweets. Add the ID of the evil tweet to that file.

* This has only been tested with SC 3.6. There are installation instructions of the version of SC [here] (http://celesteh.blogspot.co.uk/2014/04/building-supercollider-36-on-raspberry.html)
* In order to prevent the screen from dimming, you can install xscreensaver `sudo apt-get install xscreensaver` and use the GUI to disale dimming. Or else google for how to disable screen dimming
* You will need pip: 
`sudo apt-get install python-pip ;`
`sudo pip -U pip ;`
`sudo pip install tweepy ;`
`sudo pip install codecs ;`
`sudo pip install re`
* To make the mouse pointer vanish: `sudo apt-get unclutter`
* If you are planning on using a USB soundcard (a good idea since the internal one is 11 bit), you will need to patch jack: 
`sudo wget -O - http://rpi.autostatic.com/autostatic.gpg.key| sudo apt-key add - ;` 
`sudo wget -O /etc/apt/sources.list.d/autostatic-audio-raspbian.list http://rpi.autostatic.com/autostatic-audio-raspbian.list ;`
`sudo apt-get update ;`
`sudo apt-get --no-install-recommends install jackd1 ;`
`sudo apt-get --no-install-recommends install jackd2`
* Optionally: right click on the desktop to pull up a settings menu. Change the background colour to black, don't show the rubbish bin icon and change the bacground image to the svg image included in this repo. right click on the top taskbar and also set its colour to black.
* Check out this repo to a file in the pi user's home directory
* Copy the SC140_Extensions folder to your SuperCollider Extensions.
* Start sclang and run the program: `Quarks.install("XML")`
* Put your Twitter API keys into data/oauth.dat (I highly recommend you create a new twitter user for this)
* Test the installation works by first running it from the terminal: `./sc140.sh` (You will need to first cd into the directory where you saved the repo.)
* If you would like to install this on a network that requires logging in via a webpage, see the lynx-readme
* You can change the duration and some other values in sc140.config. 
  * Change `chars_per_line` to make the tweets the right length for your display.
  * Change `dur` to set each tweet's duration
  * If it crashes on startup, try increasing the value for `start_wait`

* Set the installation to start automatically on booting:
  * Edit sc140.desktop so the path in it points to where you have put the files
  * Then move the file to ~\\.config\autostart (you may need to make this directory)
  * [More information is here ] (https://www.raspberrypi.org/forums/viewtopic.php?f=26&t=18968)
* If you would prefer to get an image of an SD card that already works (aside from network credentials), get in touch.


Note that this program downloads and executed untrusted code from the internet! While some efforts are made to prevent evil misdeeds, it's very likely that a determined Twitter user could find a way to harm your computer or cause the installation to behave strangely.  Running as a dedicated user may lessen the risks, but there is still risk here. This project is not safe!
