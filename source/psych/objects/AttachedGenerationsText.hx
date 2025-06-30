package psych.objects;

class AttachedGenerationsText extends GenerationsText
{
	public var sprTracker:Null<FlxSprite> = null;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (sprTracker != null)
		{
			x = sprTracker.x + offsetX;
			y = sprTracker.y + offsetY;
		}
	}
}
