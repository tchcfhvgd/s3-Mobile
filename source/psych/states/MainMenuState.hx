package psych.states;

import psych.shaders.ColorSwap;

import flixel.group.FlxSpriteContainer;
import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.system.macros.FlxMacroUtil;

import haxe.ds.ArraySort;

import flixel.math.FlxAngle;
import flixel.addons.display.FlxBackdrop;

import psych.psychlua.ModchartSprite;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;

import lime.app.Application;

import psych.states.editors.MasterEditorMenu;
import psych.options.OptionsState;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.3'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;
	
	var menuItems:FlxTypedGroup<FlxSprite>;
	var desc:FlxSprite;
	
	// var prevDesc:FlxSprite;
	var optionShit:Array<String> = [
		'story',
		'freeplay',
		// #if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		// #if !switch 'donate', #end
		'options'
	];
	
	var greenhill:FlxSpriteContainer;
	var metal:FlxSpriteContainer;
	var white:FlxSprite;
	
	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;
		
		persistentUpdate = persistentDraw = true;
		
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
		
		var lights = new ModchartSprite(Paths.image('menu/main/Layer 5'));
		add(lights);
		
		var spike = new FlxBackdrop(Paths.image('menu/main/spkes'), X);
		add(spike);
		spike.flipY = true;
		spike.velocity.x = 50;
		
		var bar = new ModchartSprite(Paths.image('menu/main/bottomBar'));
		add(bar);
		bar.y = FlxG.height - bar.height;
		
		var spike = new FlxBackdrop(Paths.image('menu/main/spkes'), X);
		add(spike);
		spike.velocity.x = -50;
		spike.y = bar.y - spike.height;
		
		menuItems = new YDrawGroup();
		add(menuItems);
		
		final greyScale = new ColorSwap();
		greyScale.saturation = -1;
		
		for (i in 0...optionShit.length)
		{
			Paths.image('menu/main/${optionShit[i]}');
			var menuItem = new ModchartSprite(Paths.image('menu/main/${optionShit[i]}_button'));
			menuItems.add(menuItem);
			menuItem.screenCenter();
			
			switch (optionShit[i])
			{
				case 'freeplay':
					if (!ClientPrefs.data.canAccessFreeplay) menuItem.shader = greyScale.shader;
					
				case 'credits':
					if (!ClientPrefs.data.canAccessCredits) menuItem.shader = greyScale.shader;
			}
		}
		
		// prevDesc = new ModchartSprite();
		// add(prevDesc);
		// prevDesc.alpha = 0;
		
		desc = new ModchartSprite(Paths.image('menu/main/${optionShit[curSelected]}'));
		desc.screenCenter(X);
		desc.y = FlxG.height - desc.height - 20;
		add(desc);
		changeItem();
		
		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) Achievements.unlock('friday_night_play');
		
		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end
		
		addTouchPad("LEFT_RIGHT", "A_B");
		
		super.create();
	}
	
	var selectedSomethin:Bool = false;
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		
		if (!selectedSomethin)
		{
			if (controls.UI_LEFT_P) changeItem(-1);
			
			if (controls.UI_RIGHT_P) changeItem(1);
			
			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(() -> new TitleState());
			}
			
			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				
				#if RELEASE_BUILD
				// quick checks
				switch (optionShit[curSelected])
				{
					case 'freeplay':
						if (!ClientPrefs.data.canAccessFreeplay)
						{
							FlxG.camera.shake(0.001, 0.1);
							FlxG.sound.play(Paths.sound('cancelMenu'));
							return;
						}
					case 'credits':
						if (!ClientPrefs.data.canAccessCredits)
						{
							FlxG.camera.shake(0.001, 0.1);
							FlxG.sound.play(Paths.sound('cancelMenu'));
							return;
						}
				}
				#end
				
				FlxTween.tween(menuItems.members[curSelected], {'scale.x': 0.9, 'scale.y': 0.9}, 0.2, {ease: FlxEase.backOut});
				
				for (i in menuItems)
				{
					if (i == menuItems.members[curSelected]) continue;
					
					FlxTween.tween(i, {y: i.y + 70, alpha: 0}, 0.2, {startDelay: 0.1, ease: FlxEase.sineIn});
				}
				
				selectedSomethin = true;
				
				FlxTimer.wait(1, () -> {
					switch (optionShit[curSelected])
					{
						case 'story':
							FlxG.switchState(() -> new StoryMenuState());
						case 'freeplay':
							FlxG.switchState(() -> new FreeplayState());
							
						#if ACHIEVEMENTS_ALLOWED
						case 'awards':
							FlxG.switchState(() -> new AchievementsMenuState());
						#end
						
						case 'credits':
							// add a lock
							psych.states.S3CreditsMain.initiated = false;
							FlxG.switchState(() -> new psych.states.S3CreditsMain());
						case 'options':
							FlxG.switchState(() -> new OptionsState());
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
					}
				});
			}
			#if !RELEASE_BUILD
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				FlxG.switchState(() -> new MasterEditorMenu());
			}
			#end
		}
		
		if (!selectedSomethin)
		{
			final lerpRate = FlxMath.getElapsedLerp(0.35, elapsed);
			final distance = FlxAngle.asRadians(360 / menuItems.length);
			final radiusX = 200;
			final radiusY = 65;
			
			for (i in 0...menuItems.length)
			{
				var item = menuItems.members[i];
				var idx = curSelected - i;
				
				var desiredX = (FlxG.width - item.width) / 2 + radiusX * Math.cos(distance * (idx + 1));
				var desiredY = (FlxG.height - item.height) / 2 + radiusY * Math.sin(distance * (idx + 1));
				
				item.x = FlxMath.lerp(item.x, desiredX, lerpRate);
				item.y = FlxMath.lerp(item.y, desiredY, lerpRate);
				
				var desiredAlpha = i == curSelected ? 1 : 0.75;
				if (item.shader != null) desiredAlpha *= 0.5;
				
				item.alpha = FlxMath.lerp(item.alpha, desiredAlpha, lerpRate);
			}
		}
		
		super.update(elapsed);
	}
	
	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		
		curSelected = FlxMath.wrap(curSelected + huh, 0, menuItems.length - 1);
		
		// if (huh != 0)
		// {
		// 	FlxTween.cancelTweensOf(prevDesc, ['x', 'alpha']);
		
		// 	prevDesc.x = desc.x;
		// 	prevDesc.y = desc.y;
		// 	prevDesc.loadGraphicFromSprite(desc);
		
		// 	prevDesc.alpha = 1;
		
		// 	FlxTween.tween(prevDesc, {x: prevDesc.x + (huh > 0 ? -50 : 50), alpha: 0}, 0.1);
		// }
		FlxTween.cancelTweensOf(desc, ['y']);
		
		desc.loadGraphic(Paths.image('menu/main/${optionShit[curSelected]}'));
		desc.screenCenter(X);
		desc.y = FlxG.height - desc.height - 45;
		
		FlxTween.tween(desc, {y: FlxG.height - desc.height - 50}, 0.1);
	}
	
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

private class YDrawGroup extends FlxTypedGroup<FlxSprite>
{
	@:access(flixel.FlxCamera)
	override function draw()
	{
		final oldDefaultCameras = FlxCamera._defaultCameras;
		if (_cameras != null)
		{
			FlxCamera._defaultCameras = _cameras;
		}
		
		var _drawMembers = members.copy();
		ArraySort.sort(_drawMembers, (spr1, spr2) -> {
			if (spr1.y > spr2.y) return 1;
			else if (spr1.y < spr2.y) return -1;
			return 0;
		});
		
		for (basic in _drawMembers)
		{
			if (basic != null && basic.exists && basic.visible) basic.draw();
		}
		
		FlxCamera._defaultCameras = oldDefaultCameras;
	}
}
