(
var fetch, de_dup, playnew, new_tweets, old_tweets, clear_vars, wait_time, fetcher, do_fetch, dur, rout, isRaspberry,
busy, click, clicker, f_task, stop_tweet, fetch_click, monitor, fade_time, play, min_dur, bad_tweets, do_config, config;
var tweet_mod_time, rss, playing_file, alive_file;
var update_gui, tweet, window, chars_per_line;
var semaphore;




/*
TODO:

* Remove the rout from TempoClocks.all (RJK posted about this on-list) and lose the skip jack stuff aside from check if the rout is still running
* Add the syntax for that to the list of naughty words in the python script
* This should all be a class
* It should optionally generate mp3s and a podcast rss script
* Figure out how to run this all as nobody
* Make this structre less reminiscent of BASIC programs I wrote as a 9 yeard old :(

*/

semaphore = Semaphore.new;
new_tweets = [];
old_tweets = [];
bad_tweets = [];
s.options.memSize = s.options.memSize*8;
fetcher = Semaphore.new;
busy = Semaphore.new;


// Get arguments , read config file
do_config = {
	var config_path, config_arr, server_port, bad_file, tweet_arr;

	server_port = thisProcess.argv[0];

	config = IdentityDictionary.new;

	config_path = thisProcess.argv[1];
	config_path.postln;

	isRaspberry = (thisProcess.argv[2] == "1");

	if ((isRaspberry) && (server_port != "0") , {
		Server.default = Server(\Raspberry, NetAddr("localhost", server_port.asInteger));
		s = Server.default;
	});

	File.exists(config_path).if ({
		config_arr = FileReader.read(config_path, true, true, delimiter: $=);
		config_arr.do({|pair|
			(pair.size == 2).if ({ // only get get pairs
				config.put(pair[0].asSymbol, pair[1]);
				pair.postln;
			})
		});
	});

	// how long to play the tweets
	dur = config[\dur].asFloat;
	// they need to play for at least this long to come back again in the loop
	min_dur = config[\min_dur].asFloat;
	// after how many chars do we wrap the diplay text?
	chars_per_line = config[\chars_per_line].asInteger;

	// get bad tweets
	File.exists(config[\badtweets]). if ({
		bad_file = File.new(config[\badtweets], "r");
		tweet_arr = bad_file.readAllStringRTF.split($\n);
		bad_file.close;
		tweet_arr.isNil.if ({
			//bad_tweets = [];
			} , {
				tweet_arr.do({|str|
					(str.asInt != 0).if ({ // useful values will be bigger than 0
						bad_tweets = bad_tweets.add(str)
					});
				});
		})
	});

	rss = config[\rss];
	playing_file = config[\playing];
	alive_file = config[\alive];

};

do_config.();


fade_time = 45.reciprocal;

click =  {
	clicker = 2;
	"touch %".format(alive_file).unixCmd;
};

click.value;




// set up graphics
AppClock.sched(0, {
	var font, pts, fullscreen, do_win;

	"Font size is %".format(config[\font_size]).postln;
	pts = (config[\font_size]).asInt(); //50;

	Font.availableFonts.collect({|name| name.asSymbol}).includes(\Monaco).if({
		font = Font("Monaco", pts);
		} , {
			font = Font.monospace(pts);
	});

	do_win = {
		window = Window.new("#sc140", Window.availableBounds, scroll:false); // was true
		tweet = StaticText(window, Rect(10, 0,  window.bounds.width, window.bounds.height));//Rect(0, 100, window.bounds.width,

		window.view.background_(Color.black);
		window.front;
		window.fullScreen;
		fullscreen = true;

		tweet.background = Color.black;
		tweet.stringColor = Color.green;
		tweet.font = font;
		tweet.align = \left;
		tweet.string = "#sc140";


		window.view.keyDownAction = {arg view, char, modifiers, unicode, keycode;

			//"char %, modifiers %, unicode %, keycode %\n".postf(char.asInt, modifiers.asInt, unicode.asInt, keycode.asInt)
			(char.asInt == 27).if ({ //Esc key
				fullscreen.if({
					//window.endFullScreen;  //DISABLED
					}, {
						window.fullScreen;
				});
				fullscreen = fullscreen.not;
			});
		};

		// if you close the window, you get 30 seconds befor eit re-opens itself
		window.onClose = { AppClock.sched(30, {{do_win}.value.value}, nil) };

	};

	do_win.value;


	nil
});


update_gui = {|code, author, gui_fade_time = 0.2|
	var colour, steps, count, state, reformat, formatted;

	// break up the tweets after a set number of chars
	reformat = { |code, width=33|

		var new_code, last_return;


		new_code = "";
		last_return = -1;

		code.do({|char, index|
			(char == $\n).if(
				{
					last_return = index;
					new_code = new_code ++ char;
				}, {
					(index - last_return >= width).if (
						{
							char.isSpace.not.if({
								new_code = new_code++char;
							});
							new_code = new_code ++ $\n;
							last_return = index;
						} , {
							new_code = new_code++char;
					})
			});
		});

		new_code
	};


	steps = gui_fade_time.reciprocal;
	count =steps;
	state = 0;

	// state 0 is fading out
	// state 1 is setting the new text
	// state 2 is fading out

	AppClock.sched(0, {
		var return_val;

		return_val = nil;
		//state.postln;

		(state == 0).if ( // fade in
			{
				//(tweet.string == "").if ({ state = 1 }); // if there's nothing to fade, don't bother
				colour = Color.green(count.linlin(0, steps, 0, 1));
				tweet.stringColor = colour;
				count = count -1;
				return_val = gui_fade_time;

				(count < 0).if({state = 1;}); // time to move on
			} , {

				(state ==1).if ( // set the text
					{
						tweet.stringColor = Color.black;
						(code.notNil && author.notNil).if(
							{
								tweet.string = "%\n\n\t-\@%".format(reformat.(code,
								chars_per_line), author);
								return_val = 1;
								state = 2;
							} , {
								tweet.string = "";
								//return_val = nil;
						});

					},{ // fade back in
						//state.postln;
						//(tweet.string == "").if ({ return_val = nil; state = 1; tweet.stringColor = Color.black;} , {// if there's nothing to fade, don't bother
							colour = Color.green(count.linlin(1, steps, 0, 1));
							tweet.stringColor = colour;
							count = count +1;
							return_val = gui_fade_time;

							(count > steps).if({
							tweet.stringColor = Color.green;
								//state = 0;
								return_val = nil
							}); // done
						//});

				})
			}
		);

		return_val

	});
};


// remove tweets that are already on oldietms from the array newitems
de_dup = { |newitems, olditems|
	olditems.do({|played|
		newitems.do({|item, index|
			(played.id == item.id).if({ // duplication
				newitems.removeAt(index);
			})
		})
	});

	newitems;
};



do_fetch = {|semaphore, niceness, action, first = false|
	var doc, elements, channel, nodes, nice, cmd, cmd_act, tweet;

	"fetching new tweets".postln;
	fetch_click = 3;

	niceness.notNil.if({
		nice = "nice -n % ".format(niceness)
		}, {
			nice = ""
	});

	//cmd = (nice ++ "python" + pyhton_script_path);
	//cmd.postln;

	cmd_act = {

		fetch_click = 2;
		(File.mtime(rss) != tweet_mod_time).if({
			tweet_mod_time = File.mtime(rss);
			//waittime.wait;
			//"done waiting".postln;
			doc = DOMDocument.new(rss);
			channel = doc.getElementsByTagName("channel");
			nodes = channel.last.getChildNodes;
			nodes.do({|node|
				(node.getNodeName == "item").if({
					tweet = SCTweet(node);
					// skip bad tweets
					bad_tweets.includes(tweet.id.asString()).not.if({
						elements = elements.add(tweet)
					});
					//elements = elements.add(SCTweet(node));
				})
			});


			semaphore.wait;

			elements = de_dup.(elements, old_tweets);
			elements = de_dup.(elements, new_tweets);
			new_tweets = new_tweets.add(elements);
			new_tweets = new_tweets.flat;
			new_tweets = new_tweets.scramble;
			"% new tweets downloaded\n".postf(new_tweets.size);
			semaphore.signal;
			busy.signal;
			//"next".postln;
			action.notNil.if({
				action.value
			});
		}); // end if
	};

	first.if({
		File.exists(rss).if({
			tweet_mod_time = 0;
			busy.wait;
			cmd_act.fork;
			action.notNil.if({
				busy.wait;
				action = nil;
				busy.signal;
			});
		});
	});


	busy.wait;
	"fetching".postln;
	//cmd.unixCmd(cmd_act, false);
	cmd_act.value();
};


/*
fetch = { |semaphore, niceness =10|

f_task = Task({

inf.do({

fetcher.wait;
do_fetch.value(semaphore, niceness); // make it run slower
10.wait;
})
}).play;
};
*/

clear_vars = {
	/*
	a = nil;
	b = nil;
	c = nil;
	d = nil;
	e = nil;
	f = nil;
	g = nil;
	h = nil;
	i = nil;
	j = nil;
	k = nil;
	l = nil;
	m = nil;
	n = nil;
	o = nil;
	p = nil;
	q = nil;
	r = nil;
	s = Server.default;
	t = nil;
	u = nil;
	v = nil;
	w = nil;
	x = nil;
	y = nil;
	z = nil;
	*/
	this.clearAll;
	s = Server.default;
};

stop_tweet = { |tweet|
	//var ramp;

	//ramp = fade_time.reciprocal;

	CmdPeriod.doOnce({
		SkipJack(
			{
				{rout}.value.play;
				click.value;
			},

			1, name:"stop_tweet"
		);
	});

	//update_gui.();
	60.do({|i|
		Server.default.volume.volume = i* -1;
		fade_time.wait;
	});

	tweet.notNil.if({
		tweet.stop;
	});

	CmdPeriod.run;
	0.5.wait;
	SkipJack.stop("stop_tweet");
	this.clearAll;
	s = Server.default;
	click.value;
	Server.default.boot(onFailure:{});
	//Server.default.doWhenBooted({/*{rout}.value.play*/}, onFailure:{1.exit});
	Server.default.sync;
			(Server.default.serverRunning.not).if({
				// server didn't boot
				1.exit;
			});
	Server.default.volume = 0; // 0db is amp of 1
	click.value;


};

play = { |item, should_move=false, semaphore|

	var play, syn, lastrms, osc_listener, startTime, endTime;
	click.value;
	//pi
	s.boot;

	//"play".postln;
	//item.class.postln;



	item.playable.if({

		syn = Synth(\stereoListenForSilence,  nil, RootNode(Server.default), \addToTail);

		// make a note of what we're playing
		"echo \"%\" > %".format(item.id, playing_file).postln.unixCmd;

		play = item.play;

		//"playable".postln;
		//	semaphore.wait;
		//	newitems.remove(item);
		//	semaphore.signal;

		should_move.if({
			semaphore.wait;
			old_tweets = old_tweets.add(item);
			semaphore.signal;
		});


		play.if({
			//"playing".postln;
			startTime = Date.getDate;

			item.code.postln;

			//gui_fade_time = Server.local.avgCPU / 9; // higher load, fewer steps

			update_gui.(item.code, item.author, ((100 - Server.default.avgCPU) / 2.2).max(1).reciprocal);

			//should_move.if({
			//	semaphore.wait;
			//	old_tweets = old_tweets.add(item);
			//	semaphore.signal;
			//});


			//monitor for loudness

			lastrms=Array.fill(min_dur, {1});
			osc_listener = OSCFunc({ |msg|
				var rms;
				rms = msg[4].asFloat.max(msg[6].asFloat);
				lastrms.removeAt(0);
				lastrms.add(rms);
				(lastrms.sum <= 0.0001).if ({
					"too quiet".postln;
					{rout}.value.play; // skip forward
				});
			}, '/loudnessMonitoringForSuperCollider140Tweets');



			//(dur-10).wait;
			//update_gui.();
			//10.wait;
			dur.wait;

			endTime = Date.getDate;
			syn.free;
			osc_listener.free;

			// was it too short?
			((endTime.secStamp.asInt - startTime.secStamp.asInt) < (min_dur +2)).if({
				// this tweet was too short
				"too short".postln;
				item.playable=false;
			});

			click.value;
			//"done waiting".postln;
			}, {
				//"unplayable".postln;

		});
		//item.stop;
		stop_tweet.value(item);

		// remove note
		"rm %".format(playing_file).unixCmd;

		1.wait;
		click.value;
	});
};


playnew = { |semaphore|
	var newitems, item;

	//"playnew".postln;
	newitems = Routine({
		var item;
		semaphore.wait;
		new_tweets = new_tweets.scramble;
		semaphore.signal;
		{new_tweets.size >0}.while({
			semaphore.wait;
			item = new_tweets.pop;
			//"pop".postln;
			semaphore.signal;
			item.yield;
		});
	});

	//"% new items\n".postf(newitems.size);

	{(item = newitems.next).notNil}.while ({
		//"looping".postln;
		play.(item, true, semaphore);
	});

};





Task({
// pi
//s.waitForBoot(onFailure:{"didn't boot".postln; 1.exit}, onComplete: {

	var action;

	Server.default.boot;
	Server.default.sync;

	SynthDef(\stereoListenForSilence, {|in=0, out=0|
		var input;
		input = In.ar(in, Server.default.options.numOutputBusChannels);
		SendPeakRMS.kr(input, 1, 3, '/loudnessMonitoringForSuperCollider140Tweets');
		ReplaceOut.ar(0, LeakDC.ar(input).tanh);
	}).add;

	Server.default.sync;

	//s.meter;

	action = {

		SkipJack.stop("start_fetch");

		rout.notNil.if({
			rout.stop;
		});

		rout = Routine.new({

			var code, new_code, syn, play;

			Server.default.boot(onFailure:{});
			//Server.default.doWhenBooted({}, onFailure:{1.exit});
			Server.default.sync;
			(Server.default.serverRunning.not).if({
				// server didn't boot
				1.exit;
			});

			//fetcher.signal;
			//fetcher.wait;
			//fetch.value(semaphore);

			5.wait;

			"go!".postln;

			inf.do({


				click.value;
				playnew.(semaphore);
				//fetcher.signal;

				//("% old items\n").postf(old_tweets.size);
				old_tweets.do({ |tweet|
					click.value;
					playnew.(semaphore);
					play.(tweet);
					//click.value;
					//tweet.playable.if({
					//	play = tweet.play;
					//	play.if({
					//		update_gui.(tweet.code, tweet.author);
					//		dur.wait;
					//	});
					//	//"stop?".postln;
					//	//tweet.stop;
					//	stop_tweet.value;
					//	//fetcher.signal;
					//	1.wait;
					//	click.value;
					//})

				});

			});

		}).play;



		// ok, here's the part to keep everything running:

		// keep main routine running
		SkipJack({
			rout.isPlaying.if({
				//"rout is playing".postln;
				}, {
					"restarting".postln;
					rout.resume
			});

			(clicker <= 0).if({
				"rout is stuck".postln;
				//fetcher.signal;
				//f_task.play;
				rout.play
			});

			(clicker <= -1).if({
				"rout is hopelessly stuck".postln;
				//f_task.stop;
				//fetcher.signal;
				//busy.signal;
				//rout.reset;
				semaphore.signal;
				rout.play;
			});

			(clicker <= -2).if({
				//"one last try to restart the rout".postln;
				//f_task.stop;
				//fetcher.signal;
				//busy.signal;
				//semaphore.signal;
				//rout.reset;
				//rout.play;
				stop_tweet.();
				rout.reset;
				rout.play;
			});

			(clicker < -3).if({
				// we're well and truly fucked
				1.exit;
			});

			clicker = clicker -1;

			},
			dur* 1.01, name:"scweets"
		);

		// keep fetching running

		SkipJack({

			(fetch_click < -10).if({
				busy.signal;
			});

			(fetch_click < 0).if({
				do_fetch.(semaphore, 10);
			});

			fetch_click= fetch_click -1;
		}, 300, name:"fetcher");
		/*
		SkipJack({

		"///////////////////////////////////////////////////////////////////////".postln;
		"checking fetcher".postln;
		"///////////////////////////////////////////////////////////////////////".postln;

		(fetch_click < 0).if({
		"fetcher is stuck".postln;
		f_task.play;
		});

		(fetch_click < -3). if({
		"fetcher is fucked".postln;
		fetcher.signal;
		f_task.play;
		});

		(fetch_click < -6). if({
		"fetcher is beyond fucked".postln;
		busy.signal;
		fetcher.signal;
		f_task.play;
		});
		(fetch_click < -9). if({
		"lets' just start this fetching shit over".postln;
		busy.signal;
		fetcher.signal;
		fetch.value(semaphore);
		});



		fetch_click = fetch_click -1;
		},
		60*30, // check this every half an hour, so 90 minutes before first intervention
		name: "fetcher"
		);
		*/


	};




			do_fetch.(semaphore, action: action, first:true);

			SkipJack({do_fetch.(semaphore, action: action)}, 10*60, false, "start_fetch");

//})
}).play;

)


/*
(
var monitor;

SynthDef("TweetOutputLevels", {
var in = In.ar(0, 2);
SendPeakRMS.kr(in, 1, 5, "/TweetOutputLevelsOutLevels")
}).play(RootNode(Server.default), nil, \addToTail);


monitor =  OSCdef(\monitor, { |msg|
"peak: %, rms: %".format(msg[3], msg[4]).postln
}, '/TweetOutputLevels');
)

*/
