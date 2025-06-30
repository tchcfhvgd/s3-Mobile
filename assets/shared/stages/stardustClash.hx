import psych.backend.system.FunkinDefines;
import psych.backend.Paths;

import hxvlc.flixel.FlxVideoSprite;

import flixel.math.FlxMath;

import psych.objects.Character;
import psych.psychlua.ModchartSprite;

using StringTools;

var postFix:String = '';
var character = new Character(675, 500, 'stardustClash', false); // fake
var baseX = 0;
var metalDust:ModchartSprite;
var sonicDust:ModchartSprite;

function onCreate()
{
	// startCallback = startCountdown;
	
	var spr = new FlxSprite(0, 0).loadFromSheet('stages/stardust-speedway/clash', 'stardustBg');
	spr.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(spr);
	spr.x = -spr.width * 0.2;
	spr.scrollFactor.x = 0.5;
	
	addBehindDad(character);
	startCharacterPos(character);
	
	baseX = character.x;
	
	metalDust = new ModchartSprite(0, 700).loadFromSheet('stages/stardust-speedway/stardustShutdown/metalDust', 'hover dust0');
	metalDust.animation.addByPrefix('burn', 'bigger hover dust', 24);
	metalDust.animation.addByPrefix('shutdown', 'hover dust crumble', 24, false);
	metalDust.addOffset('hover dust0', 0, 0);
	metalDust.addOffset('burn', 0, 70);
	metalDust.addOffset('shutdown', 0, -10);
	
	metalDust.antialiasing = ClientPrefs.data.antialiasing;
	add(metalDust);
	metalDust.flipX = true;
	
	sonicDust = new ModchartSprite(800, 550).loadFromSheet('stages/stardust-speedway/stardustShutdown/sonicDust', 'dust');
	sonicDust.addOffset('dust', 0, 0);
	sonicDust.addOffset('speed', 800, 167);
	sonicDust.animation.addByPrefix('speed', 'bigger dust', 24, false);
	sonicDust.antialiasing = ClientPrefs.data.antialiasing;
	add(sonicDust);
	
	sonicDust.animation.onFinish.add(anim -> {
		if (anim == 'speed') sonicDust.visible = false;
	});
	
	var spr = new FlxSprite(0, 700).loadFromSheet('stages/stardust-speedway/clash', 'stardustFg');
	spr.antialiasing = ClientPrefs.data.antialiasing;
	add(spr);
	spr.scrollFactor.x = 1.25;
	
	var spr = new FlxSprite(0, 0).loadFromSheet('stages/stardust-speedway/clash', 'stardustOverlay');
	spr.antialiasing = ClientPrefs.data.antialiasing;
	spr.scale.set(2, 2);
	add(spr);
	
	// these need to be more comprehensive man
	
	character.atlas.anim.onComplete.add(() -> {
		if (character.getAnimationName() == 'shutdown') character.visible = false;
	});
	character.atlas.anim.onFrame.add(frame -> {
		if (character.getAnimationName() == 'shutdown')
		{
			if (frame == 15)
			{
				metalDust.playAnim('shutdown');
			}
			if (frame == 48)
			{
				sonicDust.playAnim('speed');
			}
		}
	});
}

function onCreatePost()
{
	gf.scale.set(0.5, 0.5);
	gf.updateHitbox();
	gf.scrollFactor.x = 0.5;
	gf.dance();
	
	dad.visible = false;
	boyfriend.visible = false;
	
	return Function_Continue;
}

function onUpdatePost(e)
{
	var newX = baseX;
	var newMetal = metalDust.originalPosition.x;
	var newSonic = sonicDust.originalPosition.x;
	
	if (health <= 1)
	{
		newX = FlxMath.remapToRange(health, 1, 0, baseX, baseX + 300);
		newSonic = FlxMath.remapToRange(health, 1, 0, sonicDust.originalPosition.x, sonicDust.originalPosition.x + 300);
		newMetal = FlxMath.remapToRange(health, 1, 0, metalDust.originalPosition.x, metalDust.originalPosition.x + 300);
	}
	
	sonicDust.x = FlxMath.lerp(sonicDust.x, newSonic, FlxMath.getElapsedLerp(0.2, e));
	metalDust.x = FlxMath.lerp(metalDust.x, newMetal, FlxMath.getElapsedLerp(0.2, e));
	
	character.x = FlxMath.lerp(character.x, newX, FlxMath.getElapsedLerp(0.2, e));
	
	setVar('gameoverExtra', {customGameOverCall: gameOverVideo, fadeCamera: camOther});
}

function gameOverVideo(resetFunc)
{
	if (FunkinDefines.defines.exists('VIDEOS_ALLOWED'))
	{
		var vid = new FlxVideoSprite();
		vid.bitmap.onFormatSetup.add(() -> {
			FlxG.camera.visible = false;
			camHUD.visible = false;
			vid.setGraphicSize(0, FlxG.height);
			vid.updateHitbox();
			vid.screenCenter();
			vid.cameras = [camOther];
		}, true);
		vid.bitmap.onEndReached.add(() -> {
			resetFunc();
		}, true);
		vid.load(Paths.video('stardust-shutdownGameover'));
		vid.play();
		insert(0, vid);
	}
	else
	{
		resetFunc();
	}
}

function onEvent(ev, v1, v2, time)
{
	if (ev == '')
	{
		switch (v1)
		{
			case 'gah':
				character.playAnim('gah', true);
				character.specialAnim = true;
				
			case 'grahhh':
				character.playAnim('grahhh', true);
				character.specialAnim = true;
				
			case 'burning':
				postFix = '-burn';
				metalDust.playAnim('burn');
			// character.playAnim('gah', true);
			// character.specialAnim = true;
			
			case 'shutdown':
				character.playAnim('shutdown', true);
				character.specialAnim = true;
				
			case 'turnoff':
				character.playAnim('turnoff', true);
				character.specialAnim = true;
		}
	}
}

var directions = ['left', 'down', 'up', 'right'];

function opponentNoteHitPre(note)
{
	if (note.noAnimation) return;
	
	character.playAnim(directions[note.noteData] + '-metal' + postFix, true);
	character.holdTimer = 0;
}

function goodNoteHitPre(note)
{
	if (note.noAnimation) return;
	character.playAnim(directions[note.noteData] + '-sonic' + postFix, true);
	character.holdTimer = 0;
}

function onBeatHit()
{
	if (character != null)
	{
		tryDance(curBeat);
	}
}

function onCountdownTick(tick, counter)
{
	if (character != null) tryDance(counter);
}

function tryDance(beat:Int)
{
	var isSinging = character.getAnimationName().startsWith('left')
		|| character.getAnimationName().startsWith('down')
		|| character.getAnimationName().startsWith('up')
		|| character.getAnimationName().startsWith('right');
		
	if (beat % character.danceEveryNumBeats == 0 && !isSinging && !character.stunned) character.dance();
}

function onUpdate(e)
{
	if (character != null)
	{
		var isSinging = character.getAnimationName().startsWith('left')
			|| character.getAnimationName().startsWith('down')
			|| character.getAnimationName().startsWith('up')
			|| character.getAnimationName().startsWith('right');
			
		if (isSinging) character.holdTimer += e;
	}
}
