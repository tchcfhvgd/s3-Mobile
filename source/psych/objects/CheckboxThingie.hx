package psych.objects;

import psych.psychlua.ModchartSprite;

class CheckboxThingie extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var daValue(default, set):Bool;
	public var copyAlpha:Bool = true;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	
	public function new(x:Float = 0, y:Float = 0, ?checked = false)
	{
		super(x, y);
		
		loadGraphic(Paths.image('menu/options/checkbox' + (checked ? '_selected' : '')));
		antialiasing = ClientPrefs.data.antialiasing;
		scale.set(0.5, 0.5);
		updateHitbox();
		
		daValue = checked;
	}
	
	override function update(elapsed:Float)
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + offsetX, sprTracker.y + offsetY);
			if (copyAlpha)
			{
				alpha = sprTracker.alpha;
			}
		}
		super.update(elapsed);
	}
	
	private function set_daValue(check:Bool):Bool
	{
		loadGraphic(Paths.image('menu/options/checkbox' + (check ? '_selected' : '')));
		
		return (daValue = check);
	}
}
