(
var fetch, de_dup, playnew, new_tweets, old_tweets, clear_vars, wait_time, fetcher, do_fetch, dur, rout, pyhton_script_path,
busy, click, clicker, f_task, stop_tweet, fetch_click, monitor, fade_time, play, min_dur;
var tweet_mod_time;
var update_gui, tweet, window, chars_per_line;
var semaphore;

// how long to play the tweets
dur = 90;
// they need to play for at least this long to come back again in the loop
min_dur = 5;
// after how many chars do we wrap the diplay text?
chars_per_line = 33;
// don't forget to edit this file to have your auth codes
pyhton_script_path = "/home/celesteh/Documents/code/sc140/sctweet.py";


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
s.options.memSize = s.options.memSize*8;
fetcher = Semaphore.new;
busy = Semaphore.new;

fade_time = 45.reciprocal;

click =  {
	clicker = 2;
	"touch /tmp/stillAlive".unixCmd;
};

click.value;



// set up graphics
AppClock.sched(0, {
	var font, pts, fullscreen, do_win;

	pts = 50;

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


update_gui = {|code, author|
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


	steps = fade_time.reciprocal;
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
				(tweet.string == "").if ({ state = 1 }); // if there's nothing to fade, don't bother
				colour = Color.green(count.linlin(0, steps, 0, 1));
				tweet.stringColor = colour;
				count = count -1;
				return_val = fade_time;

				(count < 0).if({state = 1;}); // time to move on
			} , {

				(state ==1).if ( // set the text
					{
						(code.notNil && author.notNil).if(
							{
								tweet.string = "%\n\n\t-\@%".format(reformat.(code,
								chars_per_line), author);
							} , {
								tweet.string = "";
								return_val = nil;
						});
						return_val = 1;
						state = 2;
					},{ // fade back in
						//state.postln;
						(tweet.string == "").if ({ return_val = nil}); // if there's nothing to fade, don't bother
						colour = Color.green(count.linlin(1, steps, 0, 1));
						tweet.stringColor = colour;
						count = count +1;
						return_val = fade_time;

						(count > steps).if({
							state = 0;
							return_val = nil
						}); // done

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
	var doc, elements, channel, nodes, nice, cmd, cmd_act;

	"fetching new tweets".postln;
	fetch_click = 3;

	niceness.notNil.if({
		nice = "nice -n % ".format(niceness)
		}, {
			nice = ""
	});

	cmd = (nice ++ "python" + pyhton_script_path);
	//cmd.postln;

	cmd_act = {

		fetch_click = 2;
		(File.mtime("/tmp/rss.xml") != tweet_mod_time).if({
			tweet_mod_time = File.mtime("/tmp/rss.xml");
			//waittime.wait;
			//"done waiting".postln;
			doc = DOMDocument.new("/tmp/rss.xml");
			channel = doc.getElementsByTagName("channel");
			nodes = channel.last.getChildNodes;
			nodes.do({|node|
				(node.getNodeName == "item").if({
					elements = elements.add(SCTweet(node));
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
		File.exists("/tmp/rss.xml").if({
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

	update_gui.();
	60.do({|i|
		Server.default.volume.volume = i* -1;
		fade_time.wait;
	});


	tweet.stop;

	CmdPeriod.run;
	0.5.wait;
	SkipJack.stop("stop_tweet");
	this.clearAll;
	s = Server.default;
	click.value;
	Server.default.boot(onFailure:{});
	Server.default.doWhenBooted({/*{rout}.value.play*/}, onFailure:{1.exit});
	Server.default.sync;
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

		syn = Synth(\stereoListenForSilence,  nil, RootNode(s), \addToTail);

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

			update_gui.(item.code, item.author);

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



			(dur-5).wait;
			update_gui.();
			5.wait;

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






// pi
s.waitForBoot(onFailure:{1.exit}, onComplete: {

	var action;

	SynthDef(\stereoListenForSilence, {|in=0, out=0|
		var input;
		input = In.ar(in, Server.default.options.numOutputBusChannels);
		SendPeakRMS.kr(input, 1, 3, '/loudnessMonitoringForSuperCollider140Tweets');
		ReplaceOut.ar(0, LeakDC.ar(input).tanh);
	}).add;

	//s.meter;

	action = {

		SkipJack.stop("start_fetch");

		rout.notNil.if({
			rout.stop;
		});

		rout = Routine.new({

			var code, new_code, syn, play;

			Server.default.boot(onFailure:{});
			Server.default.doWhenBooted({}, onFailure:{1.exit});
			Server.default.sync;

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

			(clicker <= -2).if({
				"rout is hopelessly stuck".postln;
				//f_task.stop;
				//fetcher.signal;
				//busy.signal;
				//rout.reset;
				semaphore.signal;
				rout.play;
			});

			(clicker <= -3).if({
				//"one last try to restart the rout".postln;
				//f_task.stop;
				//fetcher.signal;
				//busy.signal;
				//semaphore.signal;
				//rout.reset;
				//rout.play;
				1.exit;
			});

			(clicker < -4).if({
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

})

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
