package psych.objects;

import flixel.util.FlxDestroyUtil;

import psych.psychlua.ModchartSprite;

class MenuItem extends FlxSprite
{
	public var selected:Bool = false;
	
	final selectedSpr:FlxSprite;
	
	public var targetY:Float = 0;
	
	public function new(x:Float, y:Float, weekName:String = '')
	{
		super(x, y);
		loadGraphic(Paths.image('menu/story/$weekName/week'));
		antialiasing = ClientPrefs.data.antialiasing;
		
		selectedSpr = new ModchartSprite(Paths.image('menu/story/$weekName/highlight'));
	}
	
	override function draw()
	{
		super.draw();
		if (selected) selectedSpr.draw();
	}
	
	override function destroy()
	{
		super.destroy();
		FlxDestroyUtil.destroy(selectedSpr);
	}
	
	public var isFlashing(default, set):Bool = false;
	
	private var _flashingElapsed:Float = 0;
	final _flashColor = 0xFF33FFFF;
	final flashes_ps:Int = 6;
	
	public function set_isFlashing(value:Bool = true):Bool
	{
		isFlashing = value;
		_flashingElapsed = 0;
		color = (isFlashing) ? _flashColor : FlxColor.WHITE;
		return isFlashing;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		y = FlxMath.lerp((targetY * 120) + 480, y, Math.exp(-elapsed * 10.2));
		if (isFlashing)
		{
			_flashingElapsed += elapsed;
			color = (Math.floor(_flashingElapsed * FlxG.updateFramerate * flashes_ps) % 2 == 0) ? _flashColor : FlxColor.WHITE;
		}
		
		selectedSpr.x = x + (width - selectedSpr.width) / 2;
		selectedSpr.y = y + (height - (selectedSpr.height - 19)) / 2;
	}
}
