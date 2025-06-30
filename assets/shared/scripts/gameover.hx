package assets.shared.scripts;

import flixel.text.FlxText;

import psych.backend.Conductor;
import psych.backend.Highscore;
import psych.backend.CoolUtil;

import flixel.math.FlxMath;

import psych.objects.GenerationsText;
import psych.psychlua.ModchartSprite;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

import psych.backend.ClientPrefs;
import psych.backend.Mods;
import psych.backend.Paths;
import psych.objects.Character;
import psych.psychlua.LuaUtils;
import psych.psychlua.CustomSubstate;
import psych.states.FreeplayState;
import psych.states.PlayState;
import psych.states.StoryMenuState;

function onGameOver()
{
	CustomSubstate.openCustomSubstate('gameOver', true);
	return LuaUtils.Function_Stop;
}

function onCustomSubstateCreatePost(name)
{
	if (name == 'gameOver')
	{ //
		FlxG.animationTimeScale = 1;
		boyfriend.stunned = true;
		PlayState.deathCounter += 1;
		camHUD.visible = false;
		
		PlayState.gameMeta.loseLife();
		vocals.muted = true;
		opponentVocals.muted = true;
		
		if (game.gf != null && game.gf.curCharacter == 'amy')
		{
			game.gf.playAnim('pout', true);
		}
		
		var data = getVar('gameoverExtra');
		
		var hasGameover = PlayState.instance.boyfriend.animOffsets.exists('gameover');
		
		function triggerReset()
		{
			if (ClientPrefs.data.heldLives > 0)
			{
				resetState();
			}
			else
			{
				var fadeCamera = (data != null && data.fadeCamera != null) ? data.fadeCamera : FlxG.camera;
				fadeCamera.fade(FlxColor.BLACK, 0.5, false, () -> {
					FlxTimer.wait(0.1, openRetryScreen);
				});
			}
		}
		
		if (data != null && data.customGameOverCall != null) data.customGameOverCall(triggerReset);
		else if (hasGameover)
		{
			boyfriend.playAnim('gameover', true);
			boyfriend.animation.onFinish.add(anim -> triggerReset());
			
			boyfriend.animation.onFrameChange.add((anim, frame, idx) -> {
				if (data != null && data.onFrame != null && frame == data.onFrame) data.call();
			});
		}
		else
		{
			triggerReset();
		}
		
		var pos = getCharCamPos(boyfriend);
		
		var zoomAdd = 0.1;
		if (data != null && data.zoomAdd != null) zoomAdd = data.zoomAdd;
		var yAdd = 0;
		if (data != null && data.offsetY != null) yAdd = data.offsetY;
		
		FlxTween.tween(FlxG.camera.scroll, {x: (pos.x - FlxG.width / 2), y: (pos.y - FlxG.height / 2) + yAdd}, 0.2, {ease: FlxEase.cubeOut});
		FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + zoomAdd}, 0.2, {ease: FlxEase.cubeOut});
	}
}

function resetState()
{
	FlxTimer.wait(0.5, FlxG.resetState);
}

var countdownTxt;
var countdown = 10;
var continueTxt;
var countdownTooLong = false;
var player:Character;
var inRetry:Bool = false;
var canInteract = true;

// ridiculous
var fakeCurStep:Int = 0;
var fakeCurBeat:Int = 0;

function openRetryScreen()
{
	inRetry = true;
	Paths.music('S3 Game Over');
	
	// Reset the character's life count back to the default value
	PlayState.gameMeta.resetLives();
	
	FlxG.sound.playMusic(Paths.music('gameOver'), 1, false);
	
	camOther.fade(FlxColor.BLACK, 0.8, true);
	
	var blackBox = new FlxBGSprite();
	blackBox.color = FlxColor.BLACK;
	add(blackBox);
	blackBox.cameras = [camOther];
	
	var circle = new ModchartSprite(0, 0, Paths.image('characters/sonic/gameoverCircle'));
	add(circle);
	circle.cameras = [camOther];
	
	player = new Character(295, 120, 'sonic-retry', true);
	add(player);
	player.cameras = [camOther];
	
	circle.scale.set(player.scale.x, player.scale.x);
	circle.updateHitbox();
	
	circle.screenCenter(FlxAxes.X);
	circle.y = player.y + 360;
	
	player.playAnim('retryLoop', true);
	
	continueTxt = new FlxText(0, 50, FlxG.width, 'CONTINUE', 48);
	continueTxt.font = Paths.font('gaslight.ttf');
	continueTxt.alignment = 'center';
	add(continueTxt);
	continueTxt.cameras = [camOther];
	
	countdownTxt = new FlxText(0, 150, FlxG.width, Std.string(countdown), 48);
	countdownTxt.font = Paths.font('gaslight.ttf');
	countdownTxt.alignment = 'center';
	add(countdownTxt);
	countdownTxt.cameras = [camOther];
}

function onCustomSubstateUpdatePost(name, e)
{
	if (name == 'gameOver')
	{
		boyfriend.update(e);
		
		if (getVar('gameoverExtra') != null && getVar('gameoverExtra').onUpdate != null) getVar('gameoverExtra').onUpdate(e);
		
		if (game.gf != null) game.gf.update(e);
		
		if (player != null)
		{
			player.update(e);
		}
		
		if (countdownTooLong && canInteract)
		{
			continueTxt.text = 'GAME OVER';
			// continueTxt.alpha -= 0.75 * e;
			countdownTxt.alpha -= 0.75 * e;
			
			Conductor.songPosition = FlxG.sound.music.time;
			
			var oldStep:Int = fakeCurStep;
			
			var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
			
			var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
			fakeCurStep = lastChange.stepTime + CoolUtil.floorDecimal(shit, 0);
			fakeCurBeat = CoolUtil.floorDecimal(fakeCurStep / 4, 0) + 1;
			
			if (oldStep != fakeCurStep)
			{
				if (fakeCurStep % 4 == 0) fakeBeatHit();
			}
			
			if (controls.BACK)
			{
				returnToMenu();
			}
		}
		else if (inRetry && canInteract)
		{
			countdown = FlxMath.bound(countdown - e, 0, 10);
			var temp = FlxMath.roundDecimal(countdown, 0);
			countdownTxt.text = Std.string(temp);
			
			if (countdown <= 0)
			{
				countdownTooLong = true;
				FlxG.sound.playMusic(Paths.music('S3 Game Over'));
				Conductor.bpm = 98;
				
				FlxG.sound.play(Paths.sound('gameover/hammerHit'));
				player.playAnim('cancel', true);
				
				return;
			}
			
			if (controls.ACCEPT)
			{
				confirmRetry();
			}
			
			if (controls.BACK)
			{
				cancelRetry();
			}
		}
	}
}

function fakeBeatHit()
{
	if (player != null && (fakeCurBeat) % 4 == 0)
	{
		player.playAnim('cancel-loop', true);
		// FlxG.sound.play(Paths.sound('gameover/hammerHit'));
	}
}

function cancelRetry()
{
	inRetry = false;
	
	FlxG.sound.music.stop();
	FlxG.sound.play(Paths.sound('gameover/hammerHit'));
	player.playAnim('cancel', true);
	
	returnToMenu();
}

function returnToMenu()
{
	canInteract = false;
	PlayState.deathCounter = 0;
	PlayState.seenCutscene = false;
	PlayState.chartingMode = false;
	new FlxTimer().start(1.0, function(tmr:FlxTimer) {
		Mods.loadTopMod();
		
		if (PlayState.isStoryMode) FlxG.switchState(() -> new StoryMenuState());
		else FlxG.switchState(() -> new FreeplayState());
		
		FlxG.sound.playMusic(Paths.music('freakyMenu'));
	});
}

function confirmRetry()
{
	canInteract = false;
	
	inRetry = false;
	
	FlxG.sound.music.stop();
	FlxG.sound.play(Paths.sound('S3 Extra Life'));
	FlxG.sound.play(Paths.sound('gameover/woosh'));
	
	player.playAnim('confirm', true);
	player.animation.onFinish.addOnce(anim -> {
		new FlxTimer().start(0.4, function(tmr:FlxTimer) {
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function() {
				FlxG.resetState();
			});
		});
	});
}
