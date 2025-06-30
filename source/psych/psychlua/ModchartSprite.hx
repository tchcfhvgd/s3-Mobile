package psych.psychlua;

import flixel.system.FlxAssets.FlxGraphicAsset;

class ModchartSprite extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	
	public var originalPosition:FlxPoint;
	
	public function new(x:Float = 0, y:Float = 0, ?graphic:FlxGraphicAsset)
	{
		super(x, y, graphic);
		antialiasing = ClientPrefs.data.antialiasing;
		originalPosition = FlxPoint.get(x, y);
	}
	
	public function playAnim(name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
	{
		animation.play(name, forced, reverse, startFrame);
		
		var daOffset = animOffsets.get(name);
		if (animOffsets.exists(name)) offset.set(daOffset[0], daOffset[1]);
	}
	
	public function addOffset(name:String, x:Float, y:Float)
	{
		animOffsets.set(name, [x, y]);
	}
	
	override function destroy()
	{
		originalPosition.put();
		super.destroy();
	}
}
