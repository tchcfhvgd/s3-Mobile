import psych.backend.ClientPrefs;

import flixel.FlxG;

import psych.psychlua.ModchartSprite;

import flixel.FlxSprite;

import psych.objects.Subtitles;

import flixel.text.FlxText;

import psych.states.PlayState;

import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

import openfl.filters.ShaderFilter;

import psych.shaders.NTSCShader;

var subtitle:FlxText;
var weight:FlxSprite;
var boltAnim:FlxSprite;

function onCreate()
{
	startCallback = startCountdown;
	
	var spr = new FlxSprite(-1200, -900, Paths.image('stages/hard-headed/aosthBg'));
	spr.scale.set(5, 5);
	spr.updateHitbox();
	spr.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(spr);
	
	if (ClientPrefs.data.shaders)
	{
		var filter = new ShaderFilter(new NTSCShader());
		FlxG.camera.filters = [filter];
		camHUD.filters = [filter];
	}
	
	weight = new ModchartSprite(-800, -2400).loadFromSheet('stages/hard-headed/weight', 'WEIGHT CRUSH', 24, false);
	add(weight);
	weight.animation.pause();
	
	weight.scale.set(3, 3);
	weight.updateHitbox();
	weight.animation.onFrameChange.add((anim, num, idx) -> {
		if (idx == 2)
		{
			FlxG.sound.play(Paths.sound('aosth-crash'));
			FlxG.camera.shake(0.005, 0.2);
		}
	});
	
	weight.animation.onFinish.addOnce(anim -> {
		dadGroup.visible = false;
		gfGroup.visible = false;
	});
	weight.visible = false;
}

function onCreatePost()
{
	boyfriend.visible = false;
	
	FlxG.camera.zoom = 0.9;
	defaultCamZoom = 0.9;
	
	FlxG.camera._fxFadeAlpha = 1;
	FlxG.camera._fxFadeColor = FlxColor.BLACK;
	camHUD.alpha = 0;
	
	subtitle = new FlxText(0, 0, 0, '', 44);
	subtitle.font = Paths.font('vcr.ttf');
	
	subtitle.textField.background = true;
	subtitle.textField.backgroundColor = FlxColor.BLACK;
	
	subtitle.screenCenter(FlxAxes.X);
	
	subtitle.y = Subtitles.DEFAULT_Y;
	add(subtitle);
	subtitle.cameras = [camHUD];
	
	subtitle.visible = false;
	
	boltAnim = new FlxSprite(FlxG.width - 450);
	boltAnim.frames = boyfriend.frames;
	boltAnim.animation.copyFrom(boyfriend.animation);
	boltAnim.animation.play('bolt');
	insert(0, boltAnim);
	boltAnim.cameras = [camHUD];
	boltAnim.animation.pause();
	boltAnim.visible = false;
	boltAnim.animation.onFinish.add((anim) -> boltAnim.visible = false);
	
	PlayState.instance.boyfriend.animation.onFinish.add((anim) -> {
		if (anim == 'juice')
		{
			boyfriend.visible = false;
		}
	});
	
	dad.animation.onFinish.add(anim -> {
		if (anim == 'surprised')
		{
			dad.playAnim('surprised-loop');
			dad.specialAnim = true;
		}
	});
}

function onSongStart()
{
	FlxTween.tween(FlxG.camera, {_fxFadeAlpha: 0}, 12, {ease: FlxEase.sineIn});
	FlxTween.tween(FlxG.camera, {zoom: 0.5}, 12,
		{
			ease: FlxEase.sineInOut,
			onUpdate: Void -> {
				defaultCamZoom = FlxG.camera.zoom;
			},
			onComplete: Void -> {
				defaultCamZoom = 0.5;
			}
		});
}

function onEvent(ev, v1, v2, time)
{
	if (ev == '')
	{
		switch (v1)
		{
			case 'bolt':
				FlxTween.tween(boyfriend.offset, {x: 1000}, 0.1);
				boltAnim.x = FlxG.width;
				FlxTween.tween(boltAnim, {x: FlxG.width - 450}, 0.1);
				boltAnim.visible = true;
				boltAnim.animation.resume();
			case 'subs':
				subtitle.text = 'SONIC:  ' + v2;
				
				subtitle.screenCenter(FlxAxes.X);
				
				subtitle.visible = v2.length != 0;
				
			case 'poop':
				isCameraOnForcedPos = true;
				
				boyfriend.visible = true;
				
				var time = 54.76 - (time / 1000);
				
				var pos = PlayState.instance.getCharCamPos(boyfriend);
				FlxTween.tween(camFollow, {x: pos.x, y: pos.y}, time, {ease: FlxEase.sineInOut});
				FlxTween.tween(FlxG.camera, {zoom: 0.525}, time,
					{
						ease: FlxEase.sineInOut,
						onUpdate: Void -> {
							defaultCamZoom = FlxG.camera.zoom;
						},
						onComplete: Void -> {
							defaultCamZoom = 0.525;
						}
					});
			case 'showHUD':
				FlxTween.tween(camHUD, {alpha: 1}, 1);
			case 'fixZoom':
				isCameraOnForcedPos = false;
				FlxTween.tween(FlxG.camera, {zoom: 0.35}, 0.4,
					{
						ease: FlxEase.cubeOut,
						onUpdate: Void -> {
							defaultCamZoom = FlxG.camera.zoom;
						},
						onComplete: Void -> {
							defaultCamZoom = 0.35;
						}
					});
					
			case 'drop':
				weight.visible = true;
				weight.animation.resume();
		}
	}
	
	switch (ev)
	{
		case 'Change Character':
			if (v1 == 'GF' && v2 == 'aosth_grounder') gf.alpha = 1;
		case 'Play Animation':
			switch (v1)
			{
				case 'juice':
					var pos = PlayState.instance.getCharCamPos(boyfriend);
					isCameraOnForcedPos = true;
					FlxTween.tween(camFollow, {x: pos.x - 300, y: pos.y - 100}, 1);
				case 'surprised':
					gf.alpha = 0;
			}
	}
}
