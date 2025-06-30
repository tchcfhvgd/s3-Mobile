import flixel.text.FlxText.FlxTextBorderStyle;

import psych.backend.CoolUtil;

var eggman = new Character(-40, -40, 'eggman');

//
var topBar = new FlxSprite(0, -125).makeScaledGraphic(FlxG.width, 125, FlxColor.BLACK);
var bottomBar = new FlxSprite(0, FlxG.height).makeScaledGraphic(FlxG.width, 125, FlxColor.BLACK);

//
var TXT_SIZE = 64;
var txtGroup = new FlxSpriteContainer();
var sonic = new FlxText(0, 0, 0, 'SONIC.', TXT_SIZE);
var dead = new FlxText(0, 0, 0, 'DEAD OR ALIVE.', TXT_SIZE);
var is_ = new FlxText(0, 0, 0, 'IS', TXT_SIZE);
var mine = new FlxText(0, 0, 0, 'MINE.', TXT_SIZE * 2);

//
var invertShader = createRuntimeShader('blackAndRed');

//
function onCreate()
{
	// startCallback = startCountdown;
	startCharacterPos(eggman);
	eggman.scrollFactor.set(0.95, 0.95);
	addBehindDad(eggman);
	FlxTween.circularMotion(eggman, eggman.x, eggman.y, 15, 0, false, 4, true, {type: 2});
}

function onCreatePost()
{
	bottomBar.cameras = [camHUD];
	insert(0, bottomBar);
	
	topBar.cameras = [camHUD];
	insert(0, topBar);
	
	add(txtGroup);
	txtGroup.cameras = [camHUD];
	txtGroup.add(sonic);
	txtGroup.add(dead);
	txtGroup.add(is_);
	txtGroup.add(mine);
	
	for (i in txtGroup.members)
	{
		i.font = Paths.font('sa2.ttf');
		
		i.visible = false;
	}
	
	mine.setPosition(10, FlxG.height - 125 - mine.height - 35);
	is_.setPosition(10, mine.y + -is_.height + 25);
	
	dead.setPosition(10, is_.y - dead.height);
	sonic.setPosition(10, dead.y - sonic.height);
	mine.color = FlxColor.BLACK;
}

function onUpdatePost(e)
{
	if (FlxG.keys.justPressed.G)
	{
		setSongTime(75000);
	}
}

function opponentNoteHitPre(note) if (note.gfNote) note.animSuffix = '-alt';

function onEvent(ev, v1, v2, time)
{
	if (ev == '')
	{
		switch (v1)
		{
			case 'showBars':
				FlxTween.tween(bottomBar, {y: FlxG.height - bottomBar.height}, 0.5, {ease: FlxEase.sineOut});
				FlxTween.tween(topBar, {y: 0}, 0.5, {ease: FlxEase.sineOut});
				for (i in uiGroup.members)
				{
					FlxTween.tween(i, {alpha: 0.001}, 0.5);
				}
				for (i in opponentStrums.members)
				{
					FlxTween.tween(i, {alpha: 0}, 0.5);
				}
				
				isCameraOnForcedPos = true;
				var pos = getCharCamPos(dad);
				defaultCamZoom = 1.5;
				// camZooming = false;
				// FlxG.camera.zoom = defaultCamZoom;
				
				camFollow.x = pos.x - 200;
				camFollow.y = pos.y + 50;
				
				showCombo = false;
				showComboNum = false;
				showRating = false;
			case 'goBack':
				var pos = getCharCamPos(mustHitSection ? boyfriend : dad);
				
				var time = 0.5;
				
				FlxTween.tween(camFollow, {x: pos.x, y: pos.y}, time);
				FlxTween.tween(FlxG.camera, {zoom: 0.9, scrollAngle: 0}, time * 1.2,
					{
						onUpdate: Void -> defaultCamZoom = FlxG.camera.zoom,
						onComplete: Void -> {
							isCameraOnForcedPos = false;
							defaultCamZoom = 0.9;
						}
					});
					
				FlxTween.tween(bottomBar, {y: FlxG.height}, time * 0.7, {ease: FlxEase.sineIn});
				FlxTween.tween(topBar, {y: -topBar.height}, time * 0.7, {ease: FlxEase.sineIn});
				
				for (i in opponentStrums.members)
				{
					FlxTween.tween(i, {alpha: 1}, 0.5);
				}
				
				for (i in uiGroup.members)
				{
					FlxTween.tween(i, {alpha: 1}, 0.5);
				}
				
				for (i in 0...txtGroup.members.length)
				{
					FlxTimer.wait(i * 0.025, () -> txtGroup.members[i].visible = false);
				}
				
				FlxTween.num(1, 0, 0.25, {onComplete: Void -> FlxG.camera.filters.pop()}, (f) -> {
					invertShader.setFloat('u_mix', f);
				});
				camZoomingDecay /= 5;
				
				showCombo = ClientPrefs.data.showCombo;
				showComboNum = ClientPrefs.data.showCombo;
				showRating = ClientPrefs.data.showCombo;
				
			case 'showText':
				switch (v2)
				{
					case 'sonic':
						function tie() defaultCamZoom = FlxG.camera.zoom;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom + 0.05}, ((79935 - time) / 1000) - 0.1, {onUpdate: tie, onComplete: tie});
						sonic.visible = true;
						
					case 'dead':
						dead.visible = true;
						dead.text = 'DEAD';
						
					case 'or':
						dead.text = 'DEAD OR';
						
					case 'alive':
						dead.text = 'DEAD OR ALIVE.';
						
					case 'is':
						camFollow.x += 25;
						
						is_.visible = true;
						
					case 'mine':
						FlxTween.cancelTweensOf(FlxG.camera, ['zoom']);
						// FlxG.camera.flash(FlxColor.WHITE, 0.25);
						invertShader.setFloat('u_mix', 1);
						FlxG.camera.filters = [(new ShaderFilter(invertShader))];
						
						var newZoom = defaultCamZoom + 0.8;
						
						FlxTween.tween(FlxG.camera, {scrollAngle: 10, zoom: newZoom}, 0.25, {ease: FlxEase.cubeOut});
						
						mine.visible = true;
						// FlxG.camera.shake(0.001, 0.1);
						defaultCamZoom = newZoom;
						camZoomingDecay *= 5;
						// FlxG.camera.zoom += 0.1;
				}
		}
	}
	if (ev == '' && v1 == 'saxPull')
	{
		gf.playAnim('saxPull', true);
		gf.specialAnim = true;
		camFocusOverride = gf;
		defaultCamZoomMult = 1.2;
	}
	
	if (ev == '' && v1 == 'endSaxSection')
	{
		var t = (168677 - time) / 1000;
		
		isCameraOnForcedPos = true;
		camZooming = false;
		
		FlxTween.num(1.2, 1, t, {}, (f) -> {
			defaultCamZoomMult = f;
		});
		
		var pos = getCharCamPos(boyfriend);
		
		FlxTween.tween(camFollow, {x: pos.x, y: pos.y}, t);
	}
}
