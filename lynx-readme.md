lynx
====

If your internet connecion requires you to sign in via a web page, fear not, your installation can still run.  You will need to install lynx. `sudo apt-get install lynx`

* Kill the installation by opening a terminal and typing: `killall sc140.sh ;` `killall sclang ;` killall jackd ;` `killall keepAlive.sh`
* Using your favourite browser, try to access the internet. You should be redirected to the login page.
* Do not log in. Instead save the web page to the data directory. Save it as login.html. (Overwrite the existing file.)
* Using the terminal, cd to the directory where sc140.sh lives
* Run `./lynx-setup.sh`
* Enter your login credentials into the web page via lynx
* As soon as you have sucessfully logged in, quit lynx by typing 'q'
* Edit the sc140.config file. Change the need_lynx line to `need_lynx=1`
* If the login expires after some time period: 
    * Find out the timeout duration in seconds (one hour = 3600 seconds)
    * Change the timeout line to `timeout=3600` But instead of using '3600' use the number of seconds for your particular timeout (7200 for two hours, etc)
    * You may wish to take several seconds (up to a minute) off the time out line, to ensure you don't accidentally expire while in the middle of fetching new tweets
* Reboot the computer and you should see any new #sc140 tweets start appearing within a few minutes.

Note that this method will not work if there is also a captcha on the login page. However, you can still play all the provided tweets in the included XML file.


When you move the installation to a new location / network
==========================================================

If the new network also has an active portal requiring a web login, you will need to re-run lynx-setup.sh

If the new network doe not require a login, you will need to edit sc140.config to reflect this.
* Change the need_lynx line to `need_lynx=0`
* Change the timeout line to `timeout=0`
