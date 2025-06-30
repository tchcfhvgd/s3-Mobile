package psych.states.stages;

class GreenHill extends BaseStage
{
	var imagePath = 'stages/greenhill';
	var foreground:FlxSprite;
	
	override function create()
	{
		var sky = new FlxSprite(0, 0).loadGraphic(Paths.image('${imagePath}/sky'));
		sky.antialiasing = ClientPrefs.data.antialiasing;
		sky.scrollFactor.set(0.6, 0.6);
		add(sky);
		
		var waterfall = new FlxSprite(0, 0);
		waterfall.frames = Paths.getSparrowAtlas('${imagePath}/funkinhill-waterfall');
		waterfall.animation.addByPrefix('idle', "FUNKINHILL", 12, true);
		waterfall.animation.play('idle', true);
		waterfall.antialiasing = ClientPrefs.data.antialiasing;
		waterfall.scrollFactor.set(0.8, 0.8);
		add(waterfall);
		
		var ground = new FlxSprite(0, 0).loadGraphic(Paths.image('${imagePath}/grass'));
		ground.antialiasing = ClientPrefs.data.antialiasing;
		add(ground);
		
		add(gfGroup);
		add(boyfriendGroup);
		add(dadGroup);
		
		foreground = new FlxSprite(50, 500).loadGraphic(Paths.image('${imagePath}/foreground'));
		foreground.antialiasing = ClientPrefs.data.antialiasing;
		foreground.scrollFactor.set(1.2, 1.2);
		add(foreground);
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
