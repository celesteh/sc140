import tweepy
import re
import codecs

config = {}
 
file_name = "sc140.config"
config_file= open(file_name)
 
for line in config_file:
    line = line.strip()
    if line and line[0] is not "#" and line[-1] is not "=":
        var,val = line.rsplit("=",1)
        config[var.strip()] = val.strip()
 
#print config

# Consumer keys and access tokens, used for OAuth
# Get these from Twitter by registering as a developer
consumer_key = config['consumer_key']
consumer_secret = config['consumer_secret']
access_token = config['access_token']
access_token_secret = config['access_token_secret']

rss_file = config['rss']
 
# OAuth process, using the keys and tokens
auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)
 
# Creation of the actual interface, using authentication
api = tweepy.API(auth)
 
# Sample method, used to update a status
#api.update_status('Python Hello World')

# Creates the user object. The me() method returns the user whose authentication keys were used.
user = api.me()
 
print('Name: ' + user.name)
print('Location: ' + user.location)
print('Friends: ' + str(user.friends_count))


#print(tweetlist)

unique_ids = []
unique_tweets = []


#for status in (tweetlist):
    # Process the status here
   #print (status.text)
   #print (status.created_at)
   #print (status.id)
   #print (status.author.screen_name)

#   unique_ids.append(status.id)
#   unique_tweets.append(status)

# end for

# id of sc-tweeter list is 96598344
tweetlist = api.list_timeline(list_id=96598344, count=200)

# my timeline
timeline = api.home_timeline(count=100)

search_terms = ['#sctweet', '#sc140', '#supercollider', '#sc', 'SinOsc']

# ok, so get also tweets tagged #sctweet #sc140 and #supercollider
#sctweet = api.search(q='#sctweet',count=100)
#sc140 =  api.search(q='#sc140',count=100)
#supercollider =  api.search(q='#supercollider',count=100)

found = []

for term in search_terms:
    for status in tweepy.Cursor(api.search,q=term,rpp=60).items(600):
        found.append(status)

#user_ids = [27925249, 16041929, 27159398, 27215060, 52702351, 25562932, 52894611, 15373817, 38290221, 20926552,  141261188, 132238223, 1963517594]
# hey, and let's get some known sc-tweeters
#http://twitter.com/statuses/user_timeline/27925249.rss
#http://twitter.com/statuses/user_timeline/16041929.rss
#http://twitter.com/statuses/user_timeline/27159398.rss
#http://twitter.com/statuses/user_timeline/27215060.rss
#http://twitter.com/statuses/user_timeline/52702351.rss
#http://twitter.com/statuses/user_timeline/25562932.rss
#http://twitter.com/statuses/user_timeline/52894611.rss
#http://twitter.com/statuses/user_timeline/15373817.rss
#http://twitter.com/statuses/user_timeline/38290221.rss
#http://twitter.com/statuses/user_timeline/20926552.rss
#http://twitter.com/statuses/user_timeline/20926552.rss
#http://twitter.com/statuses/user_timeline/141261188.rss
#http://twitter.com/statuses/user_timeline/132238223.rss
#http://twitter.com/statuses/user_timeline/141261188.rss
#http://twitter.com/statuses/user_timeline/141261188.rss
user_ids = [27925249, 16041929, 27159398, 
27215060, #headcube
52702351, 25562932, 52894611, 15373817, 
38290221,  #rukano
141261188, 132238223, 1963517594, 454783594,
101565901, #AdamArmfield
423810028, #aucotsi
41965672, #joshpar
299572064, #Genki_ota
214991651, #mmmayang
247420409, #brunoruviaro
18938683, #Schemawound
58274583, #nankotsuteacher
93944564, #KR9000_CW
162389321, #cocorosh
70455932, #44_kwm_20
2281213501, #__DKH__
112783230, # j_liljedahl
143715809, #tonetron
16220116, #luuma
985545530 #nikkhilnani
]


for tweeter in user_ids:
    found.extend(api.user_timeline(user_id=tweeter, count=60))
      


tweets = tweetlist  + found + timeline

# filter out ones with naughty words

naughty_words = ['unixCmd', 'pipe', 'compile', 'interpret', 'PathName', 'runInTerminal', 'interpretPrint', 'systemCmd', 'prUnixCmd', 'file', 'File', 'UnixFile', 'delete', 'unixCmdInferPID', 'perform', 'preProcessor', 'executeFile', 'compileFile', 'SkipJack', 'exit', 'CmdPeriod']

code_words = ['play|scope', '\(|\{', '\)|\}',]


# sort them by id, so we only have unique ones
tweet_id = 0
safe = 1
playable = 1
#match RTs  RT\ @*?:

stat = ""

for status in (tweets):
    if status.retweeted :
        stat = status
        try:
            status = status.retweeted_status
        except Exception:
            status = stat 
            pass
    else :
        if (re.search('\ART\W+\@\w+?:\W+', status.text) != None): #this looks like a retweet
            continue 
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
                unique_tweets.append(status)
                #print (status.text)
                #print(status.author.screen_name)
        #endif safe
    #endif unique
#endfor

rss = open(rss_file, 'w')
rss.write('<?xml version="1.0" encoding="UTF-8" ?>\n<rss version="2.0">\n<channel>\n <title>Tweets</title>\n')


# stuff then into DOM file that's got ID, username, text and date
string = ""

for status in unique_tweets:
    string = unicode(' <item>\n  <title>{}</title>\n'+
    '  <description>{}</description>\n'+
    '  <guid>{}</guid>\n'+
    '  <pubDate>{}</pubDate>\n'+
    '  <author>{}</author>\n'+
    ' </item>\n', 'utf-8', 'ignore').format(str(status.id), status.text, str(status.id), str(status.created_at), status.author.screen_name)
    string = codecs.encode(string, 'utf-8', 'ignore')
    #string = str(string)
    #string = str((' <item>\n  <title>', status.author.screen_name, '</title>\n',
    #'  <description>', status.text,'</description>\n',
    #'  <guid>', status.id, '</guid>\n',
    #'  <pubDate>', status.created_at, '</pubDate>\n',
    #'  <author>', status.author.screen_name, '</author>\n',
    #' </item>\n'))
    #print(string)
    rss.write(string)
#endfor

rss.write('</channel>\n</rss>')

print ('done')

# return the newest one if it's being added or a random one if its old
