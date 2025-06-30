package assets.shared.data.scrambled;

import psych.psychlua.ModchartSprite;
import psych.objects.Subtitles;

import flixel.tweens.motion.CircularMotion;

import psych.backend.Controls;

import flixel.FlxG;
import flixel.tweens.FlxTween;

import psych.backend.ClientPrefs;

import flixel.FlxSprite;

import psych.cutscenes.DialogueBoxPsych;

var seenCutscene:Bool = false;
var spaceBar:FlxSprite;
var firstStart = true;

// eggman thingy
var isMad:Bool = false;
var speed:Float = 1;

// moto bug !
var motobugData =
	{
		// the furthest in pixels to sonic the motobug can be for successful jumping
		maxTolerence: 125.0,
		// the closest in pixels to sonic motobug can be for successful jumping
		// we put it in the negative a bit cuz sonics hitbox is a bit wider
		minTolerance: -25.0,
		// a little offset to make it visually not look weird
		missOffset: 150,
		// a const to check shit
		missed: false,
		// a const to check shit
		madeJump: false
	}
	
var motoBug:FlxSprite = new FlxSprite(getVar('stage').x + 100, getVar('stage').y - 50).loadFromSheet('stages/stardust-speedway/MOTOBUG', 'MOTOBUG');
var canPlayerJump:Bool = true;
var dadTween:CircularMotion;

function onCreate()
{
	motoBug.animation.addByPrefix('explode', 'explosion', 24, false);
	motoBug.antialiasing = ClientPrefs.data.antialiasing;
	add(motoBug);
	motoBug.visible = false;
	motoBug.animation.onFrameChange.add((animName, frameNumber, frameIndex) -> {
		switch (animName)
		{
			case 'MOTOBUG':
				motoBug.offset.set();
				
			case 'explode':
				motoBug.offset.set(60, 140);
		}
	});
	
	boyfriend.animation.onFrameChange.add((anim, frame, idx) -> {
		if (anim == 'jump' && frame == 15)
		{
			killMoto();
		}
	});
	
	boyfriend.animation.onFinish.add(anim -> {
		if (anim.indexOf('jump') != -1) canPlayerJump = true;
	});
	dadTween = FlxTween.circularMotion(dad, dad.x, dad.y, 15, 0, false, 4, true, {type: 2});
	
	dad.animation.onFinish.add(anim -> {
		if (anim == 'angry')
		{
			dad.playAnim('point', true);
			dad.specialAnim = true;
		}
	});
	
	var subs = Subtitles.fromSong('scrambled');
	if (subs != null)
	{
		add(subs);
		subs.cameras = [camHUD];
		subs.y = FlxG.height * 0.725;
	}
}

function onCreatePost()
{
	spaceBar = new ModchartSprite().loadFromSheet('stages/stardust-speedway/space', 'space', 24);
	spaceBar.setGraphicSize(300);
	spaceBar.updateHitbox();
	uiGroup.add(spaceBar);
	spaceBar.screenCenter(0x1);
	
	spaceBar.y = FlxG.height * 0.45;
	
	spaceBar.alpha = 0;
}

function killMoto()
{
	motoBug.velocity.x = 0;
	motoBug.animation.play('explode');
	motoBug.animation.onFinish.addOnce(anim -> motoBug.visible = false);
	
	FlxG.camera.shake(0.01, 0.1);
	
	FlxTween.cancelTweensOf(camFollow, ['x', 'y']);
	defaultCamZoomMult = 1;
	
	FlxG.sound.play(Paths.sound('Badnik Defeated'), 0.6);
	
	FlxTimer.wait(0.75, () -> isCameraOnForcedPos = false);
	
	if (firstStart)
	{
		FlxTween.tween(spaceBar, {alpha: 0}, 0.4);
		firstStart = false;
	}
}

function startMoto()
{
	if (firstStart)
	{
		FlxTween.tween(spaceBar, {alpha: 1}, 0.4);
	}
	// dad.playAnim('point', true);
	// dad.specialAnim = true;
	
	motoBug.animation.play('MOTOBUG');
	motoBug.x = getVar('stage').x - motoBug.width;
	motoBug.velocity.x = 525 * speed; // i feel its a bit dumb for me to use velocity maybe ill tween it
	
	motobugData.maxTolerence = 125 * speed;
	motobugData.minTolerance = -25 * speed;
	
	motoBug.visible = true;
	
	setMotoLayering(true);
	
	motobugData.madeJump = false;
	motobugData.missed = false;
	
	isCameraOnForcedPos = true;
	
	var pos = getCharCamPos(dad);
	
	FlxTween.tween(camFollow, {x: pos.x, y: pos.y}, 0.1,
		{
			onComplete: Void -> {
				FlxTween.tween(camFollow, {x: pos.x + 200, y: pos.y + 300}, 0.1, {startDelay: 1});
			}
		});
		
	camZooming = true;
}

function setMotoLayering(inFront)
{
	remove(motoBug);
	insert(members.indexOf(boyfriendGroup) + (inFront ? 1 : 0), motoBug);
}

function onUpdatePost(e)
{
	// a little weird but idm
	var motobugDistance = boyfriend.x - (motoBug.x + motoBug.width);
	
	var canMakeJump = false;
	
	if (motobugDistance >= motobugData.minTolerance && motobugDistance <= motobugData.maxTolerence)
	{
		defaultCamZoomMult = 1.05;
		moveCamera(false);
		canMakeJump = true;
	}
	else if (!motobugData.madeJump && motobugDistance < (motobugData.minTolerance - motobugData.missOffset) && !motobugData.missed)
	{
		motobugData.missed = true;
		killMoto();
		boyfriend.playAnim('hit', true);
		boyfriend.specialAnim = true;
		getVar('ringHurt')();
		health -= 0.75;
	}
	
	if (motoBug.visible && motoBug.x >= 2000) // if hes off screen stop
	{
		motoBug.visible = false;
		motoBug.velocity.x = 0;
	}
	
	if (((canMakeJump && cpuControlled) || Controls.instance.justPressed('note_extra'))
		&& canPlayerJump
		&& boyfriend.getAnimationName() != 'hit')
	{
		if (canMakeJump) // put him behind sonic
		{
			setMotoLayering(false);
			motobugData.madeJump = true;
		}
		
		canPlayerJump = false;
		boyfriend.playAnim(canMakeJump ? 'jump' : 'jumpFail');
		boyfriend.specialAnim = true;
	}
}

function goodNoteHitPre(note)
{
	canPlayerJump = true;
	
	if (boyfriend.getAnimationName().indexOf('jump') != -1 || boyfriend.getAnimationName() == 'hit')
	{
		note.noAnimation = true;
	}
}

function onEvent(ev, v1, v2, time)
{
	if (ev == 'Play Animation' && v1 == 'angry')
	{
		isMad = true;
		dadTween.duration /= 1.5;
	}
	
	if (ev == '' && v1 == 'moto') startMoto();
}

function opponentNoteHitPre(note)
{
	if (dad.getAnimationName() == 'point') note.noAnimation = true;
	note.animSuffix = isMad ? '-angry' : '';
}
