sc140
=====

Download and play SuperCollider Tweets

This requires SuperCollider, the XML SuperCollider Quark, Python. The tweepy python lib, Bash and may require lynx (see lynx-readme.md). It has been tested on Ubuntu studio and Raspbian and should run on OS X with minimal modification.

You will need to register as an app developer with Twitter in order to get API keys.
I recommend creating a twitter account specififcally for this program and following everyone currently followed by [@sc140Bot] (https://twitter.com/sc140Bot)

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
* Follow the installation instructions above
* Set the installation to start automatically on booting:
  * Edit sc140.desktop so the path in it points to where you have put the files
  * Then move the file to ~\\.config\autostart (you may need to make this directory)
  * [More information is here ] (https://www.raspberrypi.org/forums/viewtopic.php?f=26&t=18968)


Note that this program downloads and executed untrusted code from the internet! While some efforts are made to prevent evil misdeeds, it's very likely that a determined Twitter user could find a way to harm your computer or cause the installation to behave strangely.  Running as a dedicated user may lessen the risks, but there is still risk here. This project is not safe!
