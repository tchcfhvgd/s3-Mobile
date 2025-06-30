var postFix = '';
var hit:FlxSprite;

function onCreate()
{
	startCallback = hiddenCharIntro;
	
	var x = -200;
	var y = -200;
	var sky = new FlxSprite(x, y).loadFromSheet('stages/surf/assets', 'surfcasterSky');
	sky.scrollFactor.set(0.6, 0.6);
	sky.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(sky);
	
	var spr = new FlxSprite(sky.x + 81 - x - 100, sky.y + 253 - y - 100).loadFromSheet('stages/surf/assets', 'surfcasterBg');
	spr.scale.set(1.2, 1.2);
	spr.scrollFactor.set(0.8, 0.8);
	
	spr.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(spr);
	
	var spr = new FlxSprite(sky.x + 102 - x, sky.y + 476 - y).loadFromSheet('stages/surf/assets', 'surfcasterMg');
	spr.scrollFactor.set(0.95, 0.95);
	
	spr.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(spr);
	
	var spr = new FlxSprite(sky.x + 103 - x, sky.y + 795 - y).loadFromSheet('stages/surf/assets', 'boardwalk');
	spr.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(spr);
	
	spr.active = false;
	
	function setAlternate()
	{
		spr.animation.frameIndex = 1;
	}
	
	var gameoverData =
		{
			onFrame: 8,
			call: setAlternate,
			zoomAdd: 0.05,
			offsetY: 35,
			onUpdate: (e) -> {
				dad.update(e);
				dad.playAnim('shock');
			}
		}
		
	setVar('gameoverExtra', gameoverData);
	
	hit = new FlxSprite().loadFunkinSparrow('stages/surf/Hit');
	add(hit);
	hit.cameras = [camHUD];
	hit.screenCenter();
	hit.animation.addByPrefix('i', 'HIT!', 24, false);
}

function onCreatePost()
{
	var subs = Subtitles.fromSong('surf-caster');
	if (subs != null)
	{
		add(subs);
		subs.cameras = [camHUD];
	}
}

function goodNoteHitPre(note)
{
	note.animSuffix += postFix;
}

function onEvent(ev, v1, v2, time)
{
	if (ev == '')
	{
		switch (v1)
		{
			case 'froggyAlt':
				postFix = '-froggy';
				triggerEvent('Alt Idle Animation', 'bf', '-froggy');
			case 'hit':
				hit.animation.play('i');
		}
	}
	
	if (ev == 'Play Animation')
	{
		if (v1 == 'catchFroggy')
		{
			dad.playAnim('froggy', true);
			dad.specialAnim = true;
		}
	}
}
