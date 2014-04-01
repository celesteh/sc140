SCTweet {

	var <id, <date, <playcount, <code, <author, <>playable, <lastplayed, syn;

	*new { |node|
		^super.new.initFromXml(node)
	}

	initFromXml { |node|
		var val, date_str;

		playcount = 0;
		playable = true; // why not assume

		node.getChildNodes.do({|child|
			val = child.getChildNodes.first.getNodeValue;
			switch(child.getNodeName,
				"author", {author = val},
				"pubDate", {date = val},
				"guid", {id = val},
				"description", {code = val.asString},
				"playcount", {playcount = val},
				"lastplayed", {date_str = val},
				"playable", { (val==1).if({true},{false}) }
			);
		});

		date_str.notNil.if({
			try {
				date = Date(rawSeconds: date_str.asInt);
			} {date = nil }
		});
	}


	play {
		var code_func, err_func, massaged_code, compile, namedrop, has_ats, hash, results;

		err_func = {
			"Caught Error".postln;
			Server.default.freeAll;
			playable=false;
			this.stop;
			syn = nil;
		};


		compile = {
			code_func = massaged_code.compile
		};


		playable.if ({
			massaged_code = code.replace("&gt;", ">").replace("&lt;", "<").replace("&amp;", "&");
			compile.try(err_func);
			code_func.isNil.if ({
				//"didn't compile".postln;
				has_ats = true;
				//try getting rid of @blahs
				{has_ats}.while({
					results = massaged_code.findAllRegexp("\@[A-Za-z0-9\_]+");
					has_ats = (results.size > 0);
					has_ats.if({
						namedrop = results.first.last; // [[index, string]]
						{namedrop.class == Array}.while({
							results= results.flatten;
							namedrop = results.first.last;
						});
						massaged_code = massaged_code.replace(namedrop, "");
						//("nixed" + namedrop).postln;
						playable = true;
					});
				});
				compile.try(err_func);

				code_func.isNil.if({
					hash = true;
					//try getting rid of hastags
					{hash}.while({
						results = massaged_code.findAllRegexp("\#[A-Za-z0-9\_]+");
						hash = (results.size > 0);
						hash.if({

							namedrop = results.first.last; // [[[index, string]]]
							{namedrop.class == Array}.while({
								results= results.flatten;
								namedrop = results.first.last;
							});
							massaged_code = massaged_code.replace(namedrop, "");
							//("nixed" + namedrop).postln;
							playable = true;
						});
					});
					compile.try(err_func);
				});
			});

			playable.if({
				code_func.notNil.if({

					{
						"\n\n\n\n\n\n\n\n\n%\n\n\t-\@%\n\n\n\n\n".postf(massaged_code, author);
						//("By:"+ author++ ", plays" + playcount).postln;
						//massaged_code.postln;
						code = massaged_code;
						lastplayed = Date.getDate;
						playcount = playcount +1;
						syn = code_func.value;
					}.try (err_func);
					}, {
						playable = false;
						"\nBAD: %\n".postf(code);

				})
			})
		});

		//syn.notNil.if({
		//	^syn;
		//});
		^playable
	}


	stop {
		//syn.notNil.if({
		try {
			syn.stop
		};
		try {
			syn.free;
		};
		Ndef.clear;
		//Ndef.removeAll;
		Tdef.clear;
		Tdef.removeAll;
		Pdef.clear;
		Pdef.removeAll;
		ProxySpace.clearAll;
		TempoClock.all.do({|clock| clock.clear });
		Server.default.freeAll;
		syn = nil;
		//})

	}

	toXMLString {
		var string, plays;

		string = (" <item>\n  <title>%</title>\n"+
			"  <description>%</description>\n"+
			"  <guid>%</guid>\n" +
			"  <pubDate>%</pubDate>\n"+
			"  <author>%</author>\n"+
			"  <playcount>%</playcount>"
		).format(id,
			code.replace(">", "&gt;").replace(">", "&lt;").replace("&", "&amp;"),
			id, author, playcount);

		plays = 1;
		playable.not.if({ plays = 0});
		string = string ++ "  <playable>%</playable>\n".format(plays);

		lastplayed.notNil.if({
			string = string ++ "  <lastplayed>%</lastplayed>\n".format(lastplayed.rawSeconds);
		});

		string = string ++ "</item>\n\n";
	}

	== { |otherTweet|
		(otherTweet.class == SCTweet).if({
			^ (otherTweet.id == id)
		});
		^false
	}
}