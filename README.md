sc140
=====

Download and play SuperCollider Tweets

This requires SuperCollider, the XML SuperCollider Quark, Python. The tweepy python lib, Bash and may require lynx. It has been tested on Ubuntu studio and should run on OS X with minimal modification.

You will need to register as an app developer with Twitter in order to get API keys.

To install:

* Copy the SC140_Extensions folder to your SuperCollider Extensions.
* Put your Twitter API keys into sctweet.py
* Change the directory at the top of sc140.sh to the directory where you have put the project.
* If you need to start Jack, you may wish to uncomment jack_script.sh and modify it for your setup
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


Note that this program downloads and executed untrusted code from the internet! While some efforts are made to prevent evil misdeeds, it's very likely that a determined Twitter user could find a way to harm your computer or cause the installation to behave strangely.  Running as a dedicated user may lessen the risks, but there is still risk here. This project is not safe!
