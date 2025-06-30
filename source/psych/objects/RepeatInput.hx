package psych.objects;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.input.keyboard.FlxKey;

// from sword axe
class RepeatInput extends FlxBasic
{
	static final WAIT_TIME:Float = 0.3;
	static final INTERVAL:Float = 0.1;
	
	public var isPressed(default, null):Bool;
	public var key:FlxKey;
	
	var repeatTimer:Float = 0;
	var repeatStarted:Bool = false;
	
	public function new(key:FlxKey):Void
	{
		super();
		this.key = key;
		visible = false;
	}
	
	override function destroy():Void
	{
		super.destroy();
	}
	
	override function update(elapsed:Float):Void
	{
		if (FlxG.keys.checkStatus(key, JUST_PRESSED))
		{
			isPressed = true;
			repeatStarted = true;
			return;
		}
		
		if (repeatStarted)
		{
			if (FlxG.keys.checkStatus(key, RELEASED))
			{
				isPressed = repeatStarted = false;
				repeatTimer = 0;
				return;
			}
			
			repeatTimer += elapsed;
			isPressed = (repeatTimer - WAIT_TIME) / INTERVAL >= 1;
			
			if (isPressed)
			{
				repeatTimer -= INTERVAL;
			}
		}
	}
}
