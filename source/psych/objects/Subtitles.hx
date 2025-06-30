package psych.objects;

import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;

enum abstract Effects(String)
{
	var SHAKE;
}

typedef TextData =
{
	var activeStep:Int;
	var text:String;
	var ?effect:Effects;
}

typedef SubtitlesData =
{
	var subs:Array<TextData>;
	var ?highlightColour:String;
	var ?holdSteps:Int;
}

typedef MyFriendJason =
{
	var access:Array<Null<SubtitlesData>>;
}

// okay so heres the thing
// this essentially works fine however i am not interested in setting up proper sorting to ensure shit is fine
// just make sure ur json starts with min numbers and goes up from there

@:access(psych.backend.MusicBeatState)
class Subtitles extends FlxTypedSpriteContainer<FlxText>
{
	public static function fromSong(path:String):Null<Subtitles>
	{
		if (Paths.fileExists('data/' + Paths.formatToSongPath(path) + '/subs.json', TEXT))
		{
			return new Subtitles(haxe.Json.parse(File.getContent(Paths.json(Paths.formatToSongPath(path) + '/subs'))));
		}
		else return null;
	}
	
	public static var INACTIVE_COLOUR:FlxColor = FlxColor.WHITE;
	
	public static var DEFAULT_Y(get, never):Float;
	
	static function get_DEFAULT_Y() return FlxG.height * 0.725;
	
	public var data:Array<Null<SubtitlesData>> = [];
	
	var currentData:Null<SubtitlesData> = null;
	
	public function new(json:MyFriendJason)
	{
		super();
		y = DEFAULT_Y;
		data = json.access;
	}
	
	override function update(elapsed:Float)
	{
		final curStep = MusicBeatState.getState().curStep;
		
		final closestSub:Null<SubtitlesData> = data[0];
		if (closestSub != null && curStep >= getFirstStep(closestSub))
		{
			clearVisibleSubtitles();
			
			currentData = data.shift();
			
			var _lastSubtitle:Null<FlxText> = null;
			for (i in currentData.subs)
			{
				var sub = recycle(FlxText, () -> {
					var t = new FlxText(0, 0, 0, null, 38);
					t.setFormat(Paths.font('punk-mono.ttf'), 38, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
					return t;
				});
				sub.offset.set();
				sub.text = i.text;
				sub.y = 0;
				add(sub);
				
				if (_lastSubtitle != null)
				{
					sub.x = _lastSubtitle.x + _lastSubtitle.textField.textWidth;
				}
				
				_lastSubtitle = sub;
			}
			
			centerAliveMembers(); // hacky way but if u think about its smart in its dumb way
		}
		
		if (currentData != null)
		{
			var curIdx:Int = 0;
			var effect:Null<Effects> = null;
			
			for (k => i in currentData.subs)
			{
				if (curStep >= i.activeStep)
				{
					curIdx = k;
					effect = i.effect;
				}
			}
			
			final activeColour:FlxColor = currentData.highlightColour != null ? FlxColor.fromString(currentData.highlightColour) ?? FlxColor.BLUE : FlxColor.BLUE;
			
			// since there is no alivemembers array or anyhting we can just do this
			var i:Int = 0;
			forEachAlive(txt -> {
				txt.color = curIdx == i ? activeColour : INACTIVE_COLOUR;
				
				if (curIdx == i) applyEffect(txt, effect);
				
				i++;
			});
			
			final holdTime = currentData.holdSteps ?? 2;
			
			if (curStep > (getLastStep(currentData) + holdTime))
			{
				clearVisibleSubtitles();
			}
		}
		
		super.update(elapsed);
	}
	
	function applyEffect(txt:FlxText, effect:Effects)
	{
		if (effect == null) return;
		switch (effect)
		{
			case SHAKE:
				txt.offset.set(FlxG.random.int(-2, 2), FlxG.random.int(-2, 2));
		}
	}
	
	/**
	 * Resets the state to be ready for another subtitle set.
	 */
	function clearVisibleSubtitles()
	{
		forEachAlive(txt -> {
			txt.color = INACTIVE_COLOUR;
			txt.kill();
		});
		
		currentData = null;
		
		this.x = 0;
	}
	
	/**
	 * Finds the highest `activeStep` in a given subdata 
	 * @param data 
	 */
	inline function getLastStep(data:SubtitlesData)
	{
		if (data == null) return 0;
		
		var step = 0;
		for (i in data.subs)
		{
			if (i.activeStep > step) step = i.activeStep;
		}
		return step;
	}
	
	/**
	 * Finds the lowest `activeStep` in a given subdata 
	 * @param data 
	 */
	inline function getFirstStep(data:SubtitlesData)
	{
		if (data == null) return 0;
		
		var step = Math.POSITIVE_INFINITY;
		for (i in data.subs)
		{
			if (i.activeStep < step)
			{
				step = i.activeStep;
			}
		}
		return Math.floor(step);
	}
	
	inline function centerAliveMembers()
	{
		x = (FlxG.width - (findMaxAliveX() - findMinAliveX())) / 2;
	}
	
	// these arent recursive cuz they dont need to be.
	inline function findMinAliveX()
	{
		var value = Math.POSITIVE_INFINITY;
		
		forEachAlive(txt -> {
			if (txt.x < value) value = txt.x;
		});
		return value;
	}
	
	inline function findMaxAliveX()
	{
		var value = Math.NEGATIVE_INFINITY;
		
		forEachAlive(txt -> {
			if (txt.x + txt.textField.textWidth > value) value = txt.x + txt.textField.textWidth;
		});
		
		return value;
	}
}
