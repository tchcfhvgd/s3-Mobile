package psych.objects;

class UISprite extends FlxSprite
{
	public var forcedInvis:Bool = false;
	
	public var alphaMult:Float = 1;
	
	override function set_alpha(Alpha:Float):Float
	{
		if (alpha == Alpha)
		{
			return Alpha;
		}
		
		alpha *= alphaMult
		
		alpha = FlxMath.bound(Alpha, 0, 1);
		updateColorTransform();
		return alpha;
	}
	
	override function set_visible(Value:Bool):Bool
	{
		if (forcedInvis) return (visible = false);
		
		return visible = Value;
	}
}
