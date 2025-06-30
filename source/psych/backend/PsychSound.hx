package psych.backend;

// this will fix some things
class PsychSound extends FlxSound
{
	public var lockedVolume(default, set):Null<Float> = null;
	
	function set_lockedVolume(value:Null<Float>):Null<Float>
	{
		if (value != null) volume = value;
		
		return (lockedVolume = value);
	}
	
	public var muted(default, set):Bool = false;
	
	function set_muted(value:Bool):Bool
	{
		volume = 0;
		return (muted = value);
	}
	
	override function set_volume(Volume:Float):Float
	{
		if (muted) return 0;
		if (lockedVolume != null) Volume = lockedVolume;
		
		return super.set_volume(Volume);
	}
}
