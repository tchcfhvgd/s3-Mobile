package psych.objects;

enum abstract IconStyle(String)
{
	var TWO;
	var THREE;
}

class HealthIcon extends FlxSprite
{
	public var defScale:Float = 0.8;
	public var iconStyle:IconStyle = TWO;
	public var sprTracker:FlxSprite;
	
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';
	
	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}
	
	private var iconOffsets:Array<Float> = [0, 0];
	
	public function changeIcon(char:String, ?allowGPU:Bool = true)
	{
		if (this.char != char)
		{
			var name:String = 'icons/' + char;
			if (!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; // Older versions of psych engine's support
			if (!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; // Prevents crash from missing icon
			
			// if (name == 'icons/icon-face')
			// {
			// FlxG.log.error('couldnt find icon icons/$char!');
			// }
			
			var graphic = Paths.image(name, allowGPU);
			if (graphic.width >= 450) iconStyle = THREE;
			else iconStyle = TWO;
			
			final div = iconStyle == THREE ? 3 : 2;
			
			loadGraphic(graphic, true, Math.floor(graphic.width / div), Math.floor(graphic.height));
			iconOffsets[0] = (width - 150) / 2;
			iconOffsets[1] = (height - 150) / 2;
			updateHitbox();
			
			animation.add(char, [for (i in 0...div) i], 0, false, isPlayer);
			animation.play(char);
			this.char = char;
			
			if (char.endsWith('-pixel')) antialiasing = false;
			else antialiasing = ClientPrefs.data.antialiasing;
			
			if ((FlxG.state is psych.states.PlayState))
			{
				scale.set(defScale, defScale);
				updateHitbox();
			}
			
			setState(50);
		}
	}
	
	public function setState(value:Float)
	{
		switch (iconStyle)
		{
			case THREE:
				animation.frameIndex = (value >= 20 ? value >= 80 ? 0 : 1 : 2);
				
			case TWO:
				animation.frameIndex = value >= 20 ? 0 : 1;
		}
	}
	
	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}
	
	public function getCharacter():String
	{
		return char;
	}
}
