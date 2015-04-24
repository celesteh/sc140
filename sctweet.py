import tweepy
import re
import codecs
import sys
from xml.sax.saxutils import escape
from xml.dom.minidom import parse
import xml.dom.minidom


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
most_recent = 0

naughty_words = ['unixCmd', 'pipe', 'compile', 'interpret', 'PathName', 'runInTerminal', 'interpretPrint', 'systemCmd', 'prUnixCmd', 'file', 'File', 'UnixFile', 'delete', 'unixCmdInferPID', 'perform', 'preProcessor', 'executeFile', 'compileFile', 'SkipJack', 'exit', 'CmdPeriod']

code_words = ['play|scope', '\(|\{', '\)|\}',]

most_recent = 0


def playable( status ):
    "This determines if a tweet should be included in our output"

    global most_recent
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
    tweet_id = str(status.id)
    most_recent = max(most_recent, int(status.id)) #bigger number is newer
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
                unique_ids.append(str(status.id))
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

def getItem(tweet, tagName):
 
    item = tweet.getElementsByTagName(tagName)
    node = item.item(0)
    nodelist = node.childNodes
    result = []
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            result.append(node.data)
    return ''.join(result)
#end def


########### first get all previous tweets

existing_rss = config['rss']


# Open XML document using minidom parser
DOMTree = xml.dom.minidom.parse(existing_rss)
collection = DOMTree.documentElement
channel = collection.getElementsByTagName('channel')
tweets = DOMTree.getElementsByTagName('item')
for status in tweets:
    #print (status)
    guid = str(getItem(status, 'guid'))
    title = getItem(status, 'title')
    description = getItem(status, 'description')
    pubDate = getItem(status, 'pubDate')
    author = getItem(status, 'author')
    #print(guid, title, description, pubDate, author)
    if guid not in unique_ids:
        unique_ids.append(guid)
        most_recent = max(most_recent, int(guid)) #bigger number is newer
        string = unicode(' <item>\n  <title>{}</title>\n'+
        '  <description>{}</description>\n'+
        '  <guid>{}</guid>\n'+
        '  <pubDate>{}</pubDate>\n'+
        '  <author>{}</author>\n'+
        ' </item>\n', 'utf-8', 'ignore').format(str(title), escape(description), str(guid), str(pubDate), author)
        string = codecs.encode(string, 'utf-8', 'ignore')
        rss.write(string)

# then get new tweets

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


#print(most_recent)

search_terms = ['#sctweet', '#sc140', '#supercollider', '#sc', 'SinOsc', 'Pbind']

# ok, so get also tweets tagged #sctweet #sc140 and #supercollider
#sctweet = api.search(q='#sctweet',count=100)
#sc140 =  api.search(q='#sc140',count=100)
#supercollider =  api.search(q='#supercollider',count=100)

if (len(sys.argv) == 1): # no arguments

    #for tweeter in user_ids:
    user_ids = []
    for tweeter in api.friends_ids(user_id=me.id_str):
        user_ids.append(tweeter)

        for status in tweepy.Cursor(api.user_timeline, user_id=tweeter, since_id=most_recent, count=100).items(300):
            playable(status)

else: # right now we only take one argument, but this may change
    #get last tweet from file
    #prev_max=0 # obvs this will be different
    # get our timeline since last tweet
    for status in tweepy.Cursor(api.home_timeline, since_id=most_recent).items(1500):
        playable(status)

#endif

found_tweeters = []

for term in search_terms:
    #for page in range(1, 10):
        for status in tweepy.Cursor(api.search, q=term).items(200):
            if (playable(status) == 1):
                found_tweeters.append(status.author.id_str)



# let's make sure we're following everyone
for user in unique_tweeters:
    user = str(user)
    if user not in user_ids:
        #add as friend
        #api.create_friendship(user_id=user, follow=1)
        # this isn't working for some reason
        #print (user)
        #if not api.exists_friendship(user_a=me.id_str, user_b=user) :
            api.create_friendship(user_id=user, follow=1)
            for status in tweepy.Cursor(api.user_timeline, user_id=tweeter, count=100).items(300):
                playable(status)  
            #endfor          
    #endif
#endfor 

# ok, close the file
rss.write('</channel>\n</rss>')
rss.close;

#newest = open(config['working_last_fetch'], 'w')
#newest.write(str(most_recent))
#newest.close;

print ('done')


