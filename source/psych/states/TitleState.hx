package psych.states;

import openfl.system.System;

import flixel.addons.display.FlxStarField.FlxStarField2D;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.gamepad.FlxGamepad;
import flixel.addons.display.FlxBackdrop;

import psych.states.MainMenuState;

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;
	
	var finishedIntro:Bool = false;
	
	var isFU:Bool = false;
	
	var bg:FlxBackdrop;
	var waterfall:FlxBackdrop;
	
	var starField:FlxStarField2D;
	var whiteFlash:FlxSprite;
	
	var sonic:FlxSprite;
	var frame:FlxSprite;
	var ribbon:FlxSprite;
	
	var titleText:FlxText;
	
	override public function create():Void
	{
		Paths.clearStoredMemory();
		
		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();
		
		super.create();
		
		if (!initialized)
		{
			persistentUpdate = true;
			persistentDraw = true;
		}
		
		FlxG.mouse.visible = false;
		// if (FlxG.save.data.flashing == null && !FlashingState.leftState)
		// {
		// 	FlxTransitionableState.skipNextTransIn = true;
		// 	FlxTransitionableState.skipNextTransOut = true;
		// 	FlxG.switchState(() -> new FlashingState());
		// }
		// else
		// {
		startIntro();
		// }
	}
	
	#if debug
	static var tick:Int = 0;
	#end
	
	function startIntro()
	{
		if (!initialized)
		{
			if (FlxG.sound.music == null) FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
		}
		
		Conductor.bpm = 124;
		persistentUpdate = true;
		
		#if debug
		final isExe = tick == 1;
		isFU = tick == 2;
		#else
		final isExe = FlxG.random.int(1, 666) == 666;
		isFU = !isExe && FlxG.random.int(1, 1991) == 1991;
		#end
		
		var imgDir:String = isExe ? 'menu/title/exe' : 'menu/title';
		
		bg = new FlxBackdrop(Paths.image('$imgDir/sky'), X, -2);
		bg.alpha = 0;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		
		add(bg);
		
		waterfall = cast new FlxBackdrop(null, X, -2).loadFromSheet('$imgDir/titlebg', 'idle', 12);
		waterfall.antialiasing = ClientPrefs.data.antialiasing;
		waterfall.y += 2;
		waterfall.scale.scale(isExe ? 1.25 : 1);
		waterfall.alpha = 0;
		add(waterfall);
		
		starField = new FlxStarField2D();
		add(starField);
		
		whiteFlash = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		add(whiteFlash);
		whiteFlash.scrollFactor.set();
		whiteFlash.alpha = 0;
		
		frame = new FlxSprite(160.5, 0).loadGraphic(Paths.image('menu/title/frame'));
		frame.antialiasing = ClientPrefs.data.antialiasing;
		frame.scrollFactor.set();
		frame.y -= frame.height;
		add(frame);
		
		sonic = new FlxSprite(339, 76).loadMultiAtlas(['$imgDir/sonic', 'menu/title/sonic-fu']);
		sonic.antialiasing = ClientPrefs.data.antialiasing;
		sonic.animation.addByPrefix('getup', 'Sonic Get Up', 24, false);
		sonic.animation.addByPrefix('bump', 'Sonic Loop' + (isFU ? ' Finger' : '0'), 24, isFU ? true : false);
		
		sonic.animation.onFrameChange.add((anim, frame, idx) -> {
			if (anim == 'bump')
			{
				sonic.offset.set(isFU ? -167 : -150, isFU ? -22 : -20);
			}
			
			if (anim == 'getup' && frame == 54)
			{
				if (!finishedIntro)
				{
					skipIntro(false);
					if (isFU) sonic.animation.play('bump');
				}
			}
		});
		
		sonic.animation.play('getup');
		sonic.scrollFactor.set();
		add(sonic);
		
		ribbon = new FlxSprite(157.5, FlxG.height).loadGraphic(Paths.image('menu/title/ribbon'));
		ribbon.antialiasing = ClientPrefs.data.antialiasing;
		ribbon.scrollFactor.set();
		add(ribbon);
		
		titleText = new FlxText(0, 0, FlxG.width, 'Press enter to start', 72);
		titleText.setFormat(Paths.font('gaslight.ttf'), 72, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		titleText.scrollFactor.set();
		titleText.y = 625;
		titleText.alpha = 0;
		add(titleText);
		
		FlxTween.tween(frame, {y: 90}, 1, {ease: FlxEase.backInOut});
		FlxTween.tween(ribbon, {y: 410.5}, 1, {ease: FlxEase.backInOut});
		
		initialized = true;
		
		Paths.clearUnusedMemory();
		
		#if debug
		tick = FlxMath.wrap(tick + 1, 0, 2);
		#end
	}
	
	var transitioning:Bool = false;
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		
		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
		
		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end
		
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		
		if (gamepad != null)
		{
			if (gamepad.justPressed.START) pressedEnter = true;
			
			#if switch
			if (gamepad.justPressed.B) pressedEnter = true;
			#end
		}
		
		if (!finishedIntro)
		{
			if (pressedEnter) skipIntro(true);
		}
		
		if (initialized && !transitioning && finishedIntro)
		{
			if (pressedEnter)
			{
				FlxTween.cancelTweensOf(titleText, ['alpha']);
				titleText.alpha = 1;
				
				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				
				transitioning = true;
				
				FlxTween.flicker(titleText, 1, 0.08,
					{
						onComplete: Void -> {
							FlxG.switchState(() -> new MainMenuState());
						},
						endVisibility: true
					});
			}
		}
		
		if (!transitioning && FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.ONE)
		{
			transitioning = true;
			FlxG.save.erase();
			FlxG.save.bind('controls_v3', CoolUtil.getSavePath());
			FlxG.save.erase();
			
			@:privateAccess
			{
				FlxG.camera._fxFadeColor = FlxColor.BLACK;
				FlxTween.tween(FlxG.camera, {_fxFadeAlpha: 1}, 1);
			}
			FlxG.sound.music.fadeOut(1, 0, (f) -> {
				System.exit(0);
			});
		}
		super.update(elapsed);
	}
	
	override function beatHit()
	{
		super.beatHit();
		
		if (sonic != null && finishedIntro)
		{
			if (!isFU && curBeat % 2 == 0)
			{
				sonic.animation.play('bump', true);
			}
		}
	}
	
	function skipIntro(flashAll:Bool = false):Void
	{
		if (!finishedIntro)
		{
			if (flashAll)
			{
				sonic.animation.play('bump', true);
				FlxG.camera.flash(FlxColor.WHITE, 2);
			}
			else
			{
				whiteFlash.alpha = 1;
				FlxTween.tween(whiteFlash, {alpha: 0}, 2);
			}
			
			FlxTween.tween(titleText, {alpha: 1}, 2, {ease: FlxEase.sineInOut, type: 4});
			
			bg.velocity.x = -75;
			waterfall.velocity.x = -100;
			bg.alpha = 1;
			waterfall.alpha = 1;
			
			starField.visible = false;
			finishedIntro = true;
			
			FlxTween.cancelTweensOf(frame, ['y']);
			FlxTween.cancelTweensOf(ribbon, ['y']);
			
			frame.y = 90;
			ribbon.y = 410.5;
			
			for (i in [sonic, ribbon, frame]) FlxTween.tween(i, {y: i.y - 10}, 2, {ease: FlxEase.sineInOut, type: 4});
		}
	}
}
