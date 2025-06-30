package psych.objects;

import flixel.graphics.frames.FlxAtlasFrames;

class Ring extends FlxSprite
{
	public var groundY:Float = 0;
	
	var flickering:Bool = false;
	var flickCount:Int = 0;
	var flickerTime:Float = 0.1;
	
	public function new(frames:FlxAtlasFrames) // optimization no need to spam parse xmls
	{
		super();
		this.frames = frames;
		this.animation.addByPrefix('spin', 'ring', 24);
		this.animation.play('spin');
		this.animation.pause();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (this.velocity.y > 0 && this.y >= groundY) hitGround();
		
		if (flickering)
		{
			if (flickCount <= 0) kill();
			flickerTime -= elapsed;
			if (flickerTime <= 0)
			{
				flickerTime = 0.1;
				flickCount--;
				visible = !visible;
			}
		}
	}
	
	public function spawn()
	{
		this.animation.pause();
		this.animation.frameIndex = 0;
		this.visible = true;
		this.flickering = false;
	}
	
	public function hitGround()
	{
		velocity.set();
		acceleration.set();
		this.animation.resume();
		flickering = true;
		flickCount = 10;
	}
}
