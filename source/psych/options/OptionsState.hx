package psych.options;

import flixel.FlxSubState;

import psych.objects.GenerationsText;
import psych.states.MainMenuState;
import psych.backend.StageData;

import flixel.group.FlxSpriteContainer;
import flixel.addons.display.FlxBackdrop;

import psych.psychlua.ModchartSprite;

// wouldve loved to make this a substate but i dont have time for this
class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay'];
	var grpOptions:FlxTypedGroup<GenerationsText>;
	
	public var bottomBar:FlxSprite;
	
	static var curSelected:Int = 0;
	public static var onPlayState:Bool = false;
	
	var canInteract:Bool = true;
	
	function openSelectedSubstate(label:String)
	{
		switch (label)
		{
			case 'Note Colors':
				openSubState(new psych.options.NotesSubState());
			case 'Controls':
				openSubState(new psych.options.ControlsSubState());
			case 'Graphics':
				openSubState(new psych.options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new psych.options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new psych.options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				FlxG.switchState(() -> new psych.options.NoteOffsetState());
		}
	}
	
	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		FlxG.sound.play(S3Meta.getActorLine('options'));
		
		persistentUpdate = true;
		
		greenhill = new FlxSpriteContainer();
		add(greenhill);
		
		metal = new FlxSpriteContainer(-100, -50);
		add(metal);
		
		white = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		add(white);
		white.alpha = 0;
		
		makeBG();
		
		var gradient = new ModchartSprite(Paths.image('menu/main/Layer 4'));
		add(gradient);
		
		var lights = new ModchartSprite(Paths.image('menu/options/Layer_5'));
		add(lights);
		
		var spike = new FlxBackdrop(Paths.image('menu/main/spkes'), X);
		add(spike);
		spike.flipY = true;
		spike.velocity.x = 50;
		
		bottomBar = new ModchartSprite(Paths.image('menu/main/bottomBar'));
		bottomBar.y = FlxG.height - bottomBar.height;
		add(bottomBar);
		
		var spike = new FlxBackdrop(Paths.image('menu/main/spkes'), X);
		add(spike);
		spike.velocity.x = -50;
		spike.y = bottomBar.y - spike.height;
		
		grpOptions = new FlxTypedGroup<GenerationsText>();
		add(grpOptions);
		
		for (i in 0...options.length)
		{
			var optionText:GenerationsText = new GenerationsText(0, 0, 0, options[i], 48);
			optionText.screenCenter();
			optionText.y += (75 * (i - (options.length / 2))) + 25;
			grpOptions.add(optionText);
		}
		
		changeSelection();
		ClientPrefs.saveSettings();
		
		super.create();
	}
	
	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		
		bottomBar.color = FlxColor.WHITE;
		grpOptions.visible = true;
		
		FlxTimer.wait(0, () -> {
			canInteract = true;
		});
	}
	
	override function openSubState(SubState:FlxSubState)
	{
		if (SubState is psych.options.BaseOptionsMenu
			|| SubState is psych.options.ControlsSubState
			|| SubState is psych.options.NotesSubState)
		{
			bottomBar.color = FlxColor.BLACK;
			
			canInteract = false;
			grpOptions.visible = false;
		}
		super.openSubState(SubState);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (canInteract)
		{
			if (controls.UI_UP_P || controls.UI_DOWN_P) changeSelection(controls.UI_UP_P ? -1 : 1);
			
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if (onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(() -> new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else FlxG.switchState(() -> new MainMenuState());
			}
			else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		FlxTween.completeTweensOf(grpOptions.members[curSelected], ['y']);
		grpOptions.members[curSelected].color = FlxColor.WHITE;
		
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
		
		grpOptions.members[curSelected].color = FlxColor.YELLOW;
		grpOptions.members[curSelected].y += 5;
		FlxTween.tween(grpOptions.members[curSelected], {y: grpOptions.members[curSelected].y - 5}, 0.05);
		
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	
	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
	
	var greenhill:FlxSpriteContainer;
	var metal:FlxSpriteContainer;
	var white:FlxSprite;
	
	function makeBG()
	{
		var sky = new FlxSprite(0, 0).loadGraphic(Paths.image('stages/greenhill/sky'));
		sky.antialiasing = ClientPrefs.data.antialiasing;
		sky.scrollFactor.set(0.6, 0.6);
		sky.scale.scale(1.2);
		greenhill.add(sky);
		
		var waterfall = new FlxSprite(0, 0);
		waterfall.frames = Paths.getSparrowAtlas('stages/greenhill/funkinhill-waterfall');
		waterfall.animation.addByPrefix('idle', "FUNKINHILL", 12, true);
		waterfall.animation.play('idle', true);
		waterfall.antialiasing = ClientPrefs.data.antialiasing;
		waterfall.scrollFactor.set(0.8, 0.8);
		waterfall.scale.scale(1.2);
		
		greenhill.add(waterfall);
		
		var ground = new FlxSprite(0, 0).loadGraphic(Paths.image('stages/greenhill/grass'));
		ground.antialiasing = ClientPrefs.data.antialiasing;
		greenhill.add(ground);
		ground.scale.scale(1.2);
		
		var foreground = new FlxSprite(50, 500).loadGraphic(Paths.image('stages/greenhill/foreground'));
		foreground.antialiasing = ClientPrefs.data.antialiasing;
		foreground.scrollFactor.set(1.2, 1.2);
		greenhill.add(foreground);
		foreground.scale.scale(1.2);
		
		var scale = 1.2;
		var scale2 = 1.1;
		var bgX = -200;
		var bgY = -25;
		
		var spr = new FlxSprite(bgX, bgY - 250, Paths.image('stages/stardust-speedway/sky'));
		spr.scale.set(scale * scale2 * 1.2, scale * scale2 * 1.2);
		spr.updateHitbox();
		metal.add(spr);
		spr.scrollFactor.set(0.4, 0.4);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var spr = new FlxSprite(bgX + (885 * scale * scale2), bgY + (95 * scale * scale2)).loadFromSheet('stages/stardust-speedway/assets', 'eggman_statue', 24);
		spr.scale.set(scale * scale2, scale * scale2);
		spr.updateHitbox();
		metal.add(spr);
		spr.scrollFactor.set(0.4, 0.4);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var spr = new FlxSprite(bgX + (1005 * scale * scale2), bgY + (-204 * scale * scale2), Paths.image('stages/stardust-speedway/spotlight'));
		spr.scale.set(scale * scale2, scale * scale2);
		spr.updateHitbox();
		metal.add(spr);
		spr.scrollFactor.set(0.4, 0.4);
		spr.origin.set(10, 486);
		spr.angle = -70;
		FlxTween.tween(spr, {angle: 20}, 3, {ease: FlxEase.sineInOut, type: 4});
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var spr = new FlxSprite(bgX + ((1005 + 25) * scale * scale2) - spr.width, bgY + (-204 * scale * scale2), Paths.image('stages/stardust-speedway/spotlight'));
		spr.scale.set(scale * scale2, scale * scale2);
		spr.updateHitbox();
		metal.add(spr);
		spr.scrollFactor.set(0.4, 0.4);
		spr.flipX = true;
		spr.origin.set(371, 486);
		spr.angle = 70;
		FlxTween.tween(spr, {angle: -20}, 3, {ease: FlxEase.sineInOut, type: 4});
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var spr = new FlxSprite(bgX + (-69 * scale * scale2), bgY + ((224) * scale * scale2), Paths.image('stages/stardust-speedway/skyline'));
		spr.scale.set(scale * scale2, scale * scale2);
		spr.updateHitbox();
		metal.add(spr);
		spr.scrollFactor.set(0.4, 0.4);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var spr = new FlxSprite(bgX, bgY + ((1) * scale * scale2)).loadFromSheet('stages/stardust-speedway/assets', 'buildings', 24);
		spr.scale.set(scale * scale2, scale * scale2);
		spr.updateHitbox();
		metal.add(spr);
		spr.scrollFactor.set(0.7, 0.7);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var spr = new FlxSprite(1072 * scale * scale2, (150) * scale * scale2).loadFromSheet('stages/stardust-speedway/assets', 'back_platform', 24);
		spr.scale.set(scale * scale2, scale * scale2);
		spr.updateHitbox();
		metal.add(spr);
		spr.scrollFactor.set(0.9, 0.9);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var ndY = -65;
		var spr = new FlxSprite(-200 + (-255 * scale), ndY + (-320 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'front_platform', 24);
		spr.scale.set(scale, scale);
		spr.updateHitbox();
		metal.add(spr);
		spr.scrollFactor.set(0.9, 0.9);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var spr = new FlxSprite(1058 * scale, ndY + (390 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'arrow_pipe', 24);
		spr.scale.set(scale, scale);
		spr.updateHitbox();
		metal.add(spr);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var spr = new FlxSprite(-210, ndY + (465 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'stardustFloor', 24);
		spr.scale.set(scale, scale);
		spr.updateHitbox();
		metal.add(spr);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var spr = new FlxSprite(175 * scale, (597 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'piston', 24);
		spr.scale.set(scale, scale);
		spr.updateHitbox();
		metal.add(spr);
		spr.scrollFactor.set(1.4, 1);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var spr = new FlxSprite(305 * scale, (676 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'ring_set', 24);
		spr.scale.set(scale, scale);
		spr.updateHitbox();
		metal.add(spr);
		spr.scrollFactor.set(1.4, 1);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		var spr = new FlxSprite(971 * scale, (639 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'horn', 24);
		spr.scale.set(scale, scale);
		spr.updateHitbox();
		metal.add(spr);
		spr.scrollFactor.set(1.4, 1);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		
		metal.visible = false;
		
		tweenFade();
	}
	
	function tweenFade()
	{
		FlxTween.cancelTweensOf(white, ['alpha']);
		FlxTween.tween(white, {alpha: 0}, 0.4);
		
		var obj = isGreenHill ? metal : greenhill;
		obj.visible = false;
		
		var obj = isGreenHill ? greenhill : metal;
		obj.x = isGreenHill ? 0 : -200;
		obj.visible = true;
		
		FlxTween.tween(white, {alpha: 1}, 0.4, {startDelay: 4.5});
		FlxTween.tween(obj, {x: isGreenHill ? -25 : -250}, 5, {onComplete: (f) -> tweenFade()});
		isGreenHill = !isGreenHill;
	}
	
	var isGreenHill:Bool = true;
}
