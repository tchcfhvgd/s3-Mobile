function onCreate()
{
	startCallback = hiddenCharIntro;
	
	var spr = new FlxSprite(50, 0, Paths.image('stages/mania/maniaSky'));
	spr.scrollFactor.set(0.5, 0.5);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(spr);
	
	bg = new FlxSprite();
	bg.frames = (Paths.getSparrowAtlas('stages/mania/maniaBackground'));
	bg.animation.addByPrefix('mania', 'maniaBackground', 24);
	bg.animation.play('mania');
	bg.scrollFactor.set(0.7, 0.7);
	bg.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(bg);
	
	var tree2 = new FlxSprite(1055, 127, Paths.image('stages/mania/maniaTree2'));
	tree2.scrollFactor.set(0.8, 0.8);
	tree2.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(tree2);
	
	var tree1 = new FlxSprite(437, -2, Paths.image('stages/mania/maniaTree1'));
	tree1.scrollFactor.set(0.8, 0.8);
	tree1.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(tree1);
	
	var ground = new FlxSprite(-31, 500, Paths.image('stages/mania/maniaGround'));
	ground.antialiasing = ClientPrefs.data.antialiasing;
	addBehindGF(ground);
	
	bush = new FlxSprite(-28, 358);
	bush.frames = (Paths.getSparrowAtlas('stages/mania/BushBabies'));
	bush.animation.addByPrefix('1', 'bushes0', 24);
	bush.animation.addByPrefix('2', 'bushes babies0', 24, false);
	bush.animation.addByPrefix('3', 'bushes babies bop', 24, false);
	bush.animation.play('1');
	bush.antialiasing = ClientPrefs.data.antialiasing;
	bush.scale.set(0.95, 0.95);
	addBehindGF(bush);
	
	bush.animation.onFinish.add(anim -> {
		if (anim == '2') bush.animation.play('3');
	});
	
	bush.animation.onFrameChange.add((animName, frameNumber, frameIndex) -> {
		switch (animName)
		{
			case '2':
				bush.offset.set(0, 180 * 0.95);
				
			case '3':
				bush.offset.set(0, 148 * 0.95);
		}
	});
}

function onCreatePost()
{
	var subs = Subtitles.fromSong('mania');
	if (subs != null)
	{
		add(subs);
		subs.cameras = [camHUD];
		subs.y = FlxG.height * 0.725;
	}
}

function onBeatHit()
{
	if (bush != null && bush.animation.curAnim != null && bush.animation.curAnim.name == '3')
	{
		bush.animation.play('3', true);
	}
}

function onEvent(ev, v1, v2, time)
{
	if (ev == '')
	{
		switch (v1)
		{
			case 'bush1':
				bush.animation.play('2');
		}
	}
}
