import tweepy
import re
import codecs


###### get ready

config = {}
 
file_name = "sc140.config"
config_file= open(file_name)
 
for line in config_file:
    line = line.strip()
    if line and line[0] is not "#" and line[-1] is not "=":
        var,val = line.rsplit("=",1)
        config[var.strip()] = val.strip()
config_file.close()
#print config

# get oauth data
oauth = {}
file_name = '{}/oauth.dat'.format(config['data'])
config_file = open(file_name)
for line in config_file:
    line = line.strip()
    if line and line[0] is not "#" and line[-1] is not "=":
        var,val = line.rsplit("=",1)
        oauth[var.strip()] = val.strip()
config_file.close()

# Consumer keys and access tokens, used for OAuth
# Get these from Twitter by registering as a developer
consumer_key = oauth['consumer_key']
consumer_secret = oauth['consumer_secret']
access_token = oauth['access_token']
access_token_secret = oauth['access_token_secret']

#rss_file = config['rss']
rss_file = config['working_rss']

# function to determine playability and to write the file

rss = open(rss_file, 'w')
rss.write('<?xml version="1.0" encoding="UTF-8" ?>\n<rss version="2.0">\n<channel>\n <title>Tweets</title>\n')


# stuff then into DOM file that's got ID, username, text and date
string = ""


unique_ids = []
unique_tweeters = []

naughty_words = ['unixCmd', 'pipe', 'compile', 'interpret', 'PathName', 'runInTerminal', 'interpretPrint', 'systemCmd', 'prUnixCmd', 'file', 'File', 'UnixFile', 'delete', 'unixCmdInferPID', 'perform', 'preProcessor', 'executeFile', 'compileFile', 'SkipJack', 'exit', 'CmdPeriod']

code_words = ['play|scope', '\(|\{', '\)|\}',]


def playable( status ):
    "This determines if a tweet should be included in our output"
    # sort them by id, so we only have unique ones
    tweet_id = 0
    safe = 1
    playable = 0
    #match RTs  RT\ @*?:

    stat = ""

    if status.retweeted :
        stat = status
        try:
            status = status.retweeted_status
        except Exception:
            status = stat 
            pass
    else :
        if (re.search('\ART\W+\@\w+?:\W+', status.text) != None): #this looks like a retweet
            return 0 
    tweet_id = status.id
    if tweet_id not in unique_ids:
        safe = 1
        for word in naughty_words:
            if word in status.text:
                safe = 0
                break
        #endfor
        if safe == 1:
            # only grab ones with play in them
            playable = 1
            for word in code_words:
                if (re.search(word, status.text) == None):
                    playable = 0
                    break
            if playable == 1 :
                unique_ids.append(status.id)
                if status.author.id_str not in unique_tweeters:
                    unique_tweeters.append(status.author.id_str)
                    #print (status.author.screen_name)
                #print (status.text)
                #print(status.author.id_str)
                string = unicode(' <item>\n  <title>{}</title>\n'+
                '  <description>{}</description>\n'+
                '  <guid>{}</guid>\n'+
                '  <pubDate>{}</pubDate>\n'+
                '  <author>{}</author>\n'+
                ' </item>\n', 'utf-8', 'ignore').format(str(status.id), status.text, str(status.id), str(status.created_at), status.author.screen_name)
                string = codecs.encode(string, 'utf-8', 'ignore')
                rss.write(string)
        #endif safe
    #endif unique
    return playable
# enddef


########### log in and go

 
# OAuth process, using the keys and tokens
auth = tweepy.auth.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)
 
# Creation of the actual interface, using authentication
api = tweepy.API(auth)
 
# Sample method, used to update a status
#api.update_status('Python Hello World')

# Creates the user object. The me() method returns the user whose authentication keys were used.
me = api.me()
 
print('Name: ' + me.name)
print('Location: ' + me.location)
print('Friends: ' + str(me.friends_count))




search_terms = ['#sctweet', '#sc140', '#supercollider', '#sc', 'SinOsc', 'Pbind']

# ok, so get also tweets tagged #sctweet #sc140 and #supercollider
#sctweet = api.search(q='#sctweet',count=100)
#sc140 =  api.search(q='#sc140',count=100)
#supercollider =  api.search(q='#supercollider',count=100)


for term in search_terms:
    #for page in range(1, 10):
        for status in tweepy.Cursor(api.search, q=term).items(200):
            playable(status)

#for tweeter in user_ids:
user_ids = []
for tweeter in api.friends_ids(user_id=me.id_str):
    user_ids.append(tweeter)

    for status in tweepy.Cursor(api.user_timeline, user_id=tweeter, count=100).items(300):
        playable(status)

# ok, close the file
rss.write('</channel>\n</rss>')
rss.close;

# let's make sure we're following everyone
for user in unique_tweeters:
    if user not in user_ids:
        #add as friend
        api.create_friendship(user_id=user, follow=1)
    #endif
#endfor 




print ('done')


