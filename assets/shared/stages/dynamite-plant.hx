var sonicShadow;
var beanShadow;

function onCreate()
{
	startCallback = hiddenCharIntro;
	// startCallback = startCountdown;
	
	var spr = new FlxSprite(0, -200, Paths.image('stages/dynamite-plant/dynamiteSky'));
	spr.scrollFactor.set(0.8, 0.8);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(spr);
	
	var spr = new FlxSprite(0, 0).loadFromSheet('stages/dynamite-plant/dynamiteFloor', 'dynamiteFloor');
	spr.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(spr);
	
	var spr = new FlxSprite(10, -160, Paths.image('stages/dynamite-plant/dynamiteGate'));
	spr.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(spr);
	
	bg3d = new FlxSprite(0, -400, Paths.image('stages/dynamite-plant/stf'));
	addBehindGF(bg3d);
	
	bg3d.visible = false;
	
	addCharacterToList('stf-bean', 1);
	addCharacterToList('stf-sonic', 0);
}

function onCreatePost()
{
	// go3d();
	
	beanShadow = new FlxSkewedSprite();
	beanShadow.frames = dadMap.get('stf-bean').frames;
	beanShadow.animation.copyFrom(dadMap.get('stf-bean').animation);
	addBehindDad(beanShadow);
	beanShadow.active = false;
	beanShadow.skew.x = -40;
	beanShadow.color = FlxColor.BLACK;
	beanShadow.alpha = 0.6;
	
	sonicShadow = new FlxSkewedSprite();
	sonicShadow.frames = boyfriendMap.get('stf-sonic').frames;
	sonicShadow.animation.copyFrom(boyfriendMap.get('stf-sonic').animation);
	addBehindBF(sonicShadow);
	sonicShadow.active = false;
	sonicShadow.skew.x = 40;
	sonicShadow.color = FlxColor.BLACK;
	sonicShadow.alpha = 0.6;
	
	setVar('gameoverExtra', {onUpdate: (e) -> updateSonicShadow()});
}

function updateSonicShadow()
{
	if (sonicShadow.visible)
	{
		sonicShadow.animation.play(boyfriend.getAnimationName());
		sonicShadow.animation.curAnim.curFrame = boyfriend.getCurAnimFrame();
		sonicShadow.x = boyfriend.x + 140;
		sonicShadow.y = boyfriend.y + (boyfriend.height - 115);
		sonicShadow.offset.x = boyfriend.offset.x;
		sonicShadow.offset.y = boyfriend.offset.y;
		sonicShadow.flipY = true;
		
		if (boyfriend.getAnimationName().indexOf('singDOWN') != -1)
		{
			sonicShadow.offset.y += -30;
		}
	}
}

function onUpdatePost(e)
{
	// not perfect but done in like 5 mins so wahetver
	beanShadow.visible = dad.curCharacter == 'stf-bean';
	sonicShadow.visible = boyfriend.curCharacter == 'stf-sonic';
	
	updateSonicShadow();
	
	if (beanShadow.visible)
	{
		beanShadow.animation.play(dad.getAnimationName());
		beanShadow.animation.curAnim.curFrame = dad.getCurAnimFrame();
		beanShadow.x = dad.x - 200;
		beanShadow.y = dad.y + (dad.height - 80);
		beanShadow.offset.x = dad.offset.x;
		beanShadow.offset.y = dad.offset.y;
		beanShadow.flipY = true;
		
		if (dad.getAnimationName().indexOf('singDOWN') != -1)
		{
			beanShadow.offset.y += -2;
		}
	}
}

function goodNoteHit(note) {}

function onEvent(ev, v1, v2, time)
{
	if (ev == '' && v1 == 'zoom')
	{
		defaultCamZoom = Std.parseFloat(v2);
		// FlxG.camera.zoom = defaultCamZoom;
	}
	if (ev == '' && v1 == 'set3d') go3d(v2 == 'true');
	if (ev == '' && v1 == 'going3d')
	{
		//
		// go3d();
		// bad transition idk man i got no time
		FlxG.camera.alpha = 0.0001;
		FlxTimer.wait((71320 - time) / 1000, go3d);
		
		// 71.32
	}
}

function go3d(orNot)
{
	if (!orNot)
	{
		bg3d.visible = false;
		
		triggerEvent('Change Character', 'dad', 'bean', Conductor.songPosition);
		triggerEvent('Change Character', 'bf', 'sonic', Conductor.songPosition);
		return;
	}
	
	bg3d.visible = true;
	
	triggerEvent('Change Character', 'dad', 'stf-bean', Conductor.songPosition);
	triggerEvent('Change Character', 'bf', 'stf-sonic', Conductor.songPosition);
	
	// defaultCamZoom = 0.6;
}
