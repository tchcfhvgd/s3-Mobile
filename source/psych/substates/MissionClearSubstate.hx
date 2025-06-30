package psych.substates;

import psych.psychlua.ModchartSprite;

import flixel.system.FlxAssets.FlxShader;

// was gonna do null safety but got lazy
class MissionClearSubstate extends MusicBeatSubstate
{
	final nextJob:Void->Void;
	var optionalName = PlayState.SONG.song;
	
	public function new(nextJob:Void->Void, ?songName:String)
	{
		super();
		this.nextJob = nextJob;
		if (songName != null) optionalName = songName;
	}
	
	function forcePauseGame()
	{
		FlxG.camera.followLerp = 0;
		PlayState.instance.persistentUpdate = false;
		PlayState.instance.persistentDraw = true;
		PlayState.instance.paused = true;
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			PlayState.instance.vocals.pause();
		}
		@:privateAccess
		if (PlayState.instance.cameraZoomTween != null) PlayState.instance.cameraZoomTween.active = false;
	}
	
	function makeText(x:Float = 0, y:Float = 0, txt:String = '', useGradient:Bool = false)
	{
		final ret = new FlxText(x, y, 0, txt, 36);
		ret.font = Paths.font('ratingsBold.otf');
		
		ret.borderStyle = OUTLINE;
		ret.borderColor = FlxColor.BLACK;
		ret.borderSize = 2;
		if (useGradient) ret.shader = gradientShader;
		return ret;
	}
	
	final RANKING = S3Meta.queryRank(PlayState.instance?.ratingPercent ?? 0);
	
	final gradientShader = new GradientShader();
	
	var topBox:Null<FlxSprite> = null;
	var bottomBox:Null<FlxSprite> = null;
	var orangeBox:Null<FlxSprite> = null;
	
	var scoreTxt:Null<FlxText> = null;
	var comboTxt:Null<FlxText> = null;
	var missesTxt:Null<FlxText> = null;
	
	var notesHitTxt:Null<FlxText> = null;
	
	var score:Null<FlxText> = null;
	var combo:Null<FlxText> = null;
	var misses:Null<FlxText> = null;
	var notesHit:Null<FlxText> = null;
	
	var rankTxt:Null<FlxSprite> = null;
	var rank:Null<FlxSprite> = null;
	
	var actClearText:Null<FlxText> = null;
	
	var isTallying:Bool = true;
	
	var intendedScore:Int = 0;
	
	override function create()
	{
		super.create();
		
		forcePauseGame();
		
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		
		Paths.sound('s3 level clear');
		Paths.sound('ranking/rank');
		Paths.sound('ranking/hit');
		Paths.sound('ranking/scoreTally');
		
		intendedScore = PlayState.instance?.songScore ?? 0;
		
		var bg = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);
		bg.alpha = 0;
		
		final x:Float = -125;
		final y:Float = -200;
		
		topBox = new ModchartSprite(x + 346, y + 303).loadFromSheet('ratings/results', 'top box', 24, false);
		add(topBox);
		topBox.screenCenter(X);
		
		orangeBox = new ModchartSprite(FlxG.width, y + 514).loadFromSheet('ratings/results', 'yellow box', 24, false);
		add(orangeBox);
		orangeBox.animation.finish();
		
		bottomBox = new ModchartSprite(topBox.x, y + 590).loadFromSheet('ratings/results', 'bottom box', 24, false);
		add(bottomBox);
		
		for (i in [bottomBox, topBox, orangeBox])
		{
			i.animation.pause();
			i.visible = false;
		}
		
		scoreTxt = makeText(topBox.x + 30, topBox.y + 25, 'SCORE');
		add(scoreTxt);
		
		score = makeText(topBox.x + 30, scoreTxt.y, '0');
		add(score);
		
		comboTxt = makeText(topBox.x + 30, topBox.y + 25 + (scoreTxt.height * 2.25), 'HIGHEST COMBO');
		add(comboTxt);
		
		combo = makeText(topBox.x + 30, comboTxt.y, Std.string(PlayState.instance?.highestCombo ?? 0));
		add(combo);
		
		missesTxt = makeText(topBox.x + 30, bottomBox.y + 25 + 30, 'MISSES', true);
		add(missesTxt);
		
		misses = makeText(topBox.x + 30, missesTxt.y, Std.string(PlayState.instance?.songMisses ?? 0), true);
		add(misses);
		
		notesHitTxt = makeText('NOTES HIT');
		add(notesHitTxt);
		
		notesHit = makeText(Std.string(Math.floor(PlayState.instance?.totalPlayed ?? 0)));
		add(notesHit);
		
		actClearText = makeText(0, 50, (optionalName) + ' CLEARED');
		actClearText.alignment = CENTER;
		actClearText.fieldWidth = FlxG.width;
		actClearText.visible = false;
		add(actClearText);
		
		rankTxt = new ModchartSprite(0, bottomBox.y + bottomBox.height + 5).loadFromSheet('ratings/results', 'rank text');
		rankTxt.updateHitbox();
		rankTxt.screenCenter(X);
		add(rankTxt);
		
		rank = new ModchartSprite(0, rankTxt.y + rankTxt.height + 10).loadFromSheet('ratings/ranks', RANKING, 24, RANKING != 'E');
		add(rank);
		rank.animation.pause();
		rank.screenCenter(X);
		
		for (i in [rankTxt, rank, scoreTxt, comboTxt, missesTxt, score, combo, misses]) i.visible = false;
		
		inline function triggerBoxes()
		{
			showThing(actClearText, false, true);
			bottomBox.visible = topBox.visible = orangeBox.visible = true;
			bottomBox.animation.resume();
			topBox.animation.resume();
			
			FlxTween.tween(orangeBox, {x: topBox.x + 214}, 0.2, {startDelay: 0.4});
			
			FlxTween.tween(bg, {alpha: 0.7}, 0.3);
			
			topBox.animation.onFinish.addOnce(animName -> {
				for (k => i in [[score, scoreTxt], [combo, comboTxt], [misses, missesTxt]])
				{
					FlxTimer.wait(0.4 * k, () -> {
						i[1].visible = true;
						
						showThing(i[0]);
						if (k == 0) // do not keep this wait till shit is figured otu
						{
							FlxTimer.wait(0.5, () -> {
								canTally = true;
							});
						}
					});
				}
			});
		}
		
		FlxG.sound.play(Paths.sound('win-sonic'));
		FlxG.sound.play(Paths.sound('s3 level clear'));
		
		if (PlayState.instance == null || !PlayState.instance.boyfriend.animOffsets.exists('WIN'))
		{
			triggerBoxes();
			return;
		}
		
		FlxTween.tween(PlayState.instance.camHUD, {alpha: 0}, 0.2);
		
		final pos = PlayState.instance.getCharCamPos(PlayState.instance.boyfriend);
		FlxTween.tween(FlxG.camera, {'scroll.x': pos.x - (FlxG.width / 2), 'scroll.y': pos.y - (FlxG.height / 2), zoom: PlayState.instance.defaultCamZoom}, 0.2, {ease: FlxEase.sineOut});
		
		PlayState.instance.boyfriend.debugMode = true;
		
		if (PlayState.instance.gf != null && PlayState.instance.gf.animOffsets.exists('WIN'))
		{
			PlayState.instance.gf.debugMode = true;
			
			PlayState.instance.gf.playAnim('WIN');
		}
		
		if (PlayState.instance.boyfriend.animOffsets.exists('WIN'))
		{
			PlayState.instance.boyfriend.playAnim('WIN');
			
			PlayState.instance.boyfriend.animation.onFinish.addOnce(animName -> triggerBoxes());
		}
	}
	
	inline function showRank()
	{
		rankTxt.visible = true;
		rank.animation.resume();
		
		showThing(rank, true);
		FlxTimer.wait(0.4, () -> {
			FlxG.sound.play(Paths.sound('ranking/voicelines/$RANKING'), 1.0, false, null, true, () -> {
				FlxTimer.wait(1, () -> {
					PlayState.instance.camOther.fade(FlxColor.BLACK, 1, false, nextJob);
				});
			});
		});
	}
	
	function showThing(spr:FlxSprite, rankSfx:Bool = false, muted:Bool = false)
	{
		if (!muted) FlxG.sound.play(Paths.sound('ranking/' + (rankSfx ? 'rank' : 'hit')));
		spr.visible = true;
		spr.scale.scale(3);
		FlxTween.tween(spr, {'scale.x': 1, 'scale.y': 1}, 0.1);
	}
	
	var canTally = false;
	var finishedTallying:Bool = false;
	var tallyRate = 1 / 8;
	var e = 0.0;
	var tallySound = FlxG.sound.load(Paths.sound('ranking/scoreTally'));
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (PlayState.instance != null)
		{
			if (PlayState.instance.boyfriend != null
				&& PlayState.instance.boyfriend.debugMode) PlayState.instance.boyfriend.update(elapsed);
			if (PlayState.instance.gf != null && PlayState.instance.gf.debugMode) PlayState.instance.gf.update(elapsed);
		}
		
		e += elapsed;
		if (e >= tallyRate)
		{
			e = 0;
			
			if (canTally && !finishedTallying)
			{
				tallySound.play(true);
			}
		}
		
		if (canTally && !finishedTallying)
		{
			var _score = Std.parseInt(score.text);
			
			var newScore = Math.round(FlxMath.lerp(_score, intendedScore, FlxMath.getElapsedLerp(0.15, elapsed)));
			
			if (Math.abs(newScore - intendedScore) <= 10) newScore = intendedScore;
			
			score.text = Std.string(newScore);
			
			if (newScore == intendedScore)
			{
				finishedTallying = true;
				FlxTimer.wait(2, showRank);
			}
		}
		
		// alignment
		if (topBox != null)
		{
			if (score != null) score.x = topBox.x + 30 + topBox.width - score.width - 65;
			if (combo != null) combo.x = topBox.x + 30 + topBox.width - combo.width - 65;
			if (misses != null) misses.x = topBox.x + 30 + topBox.width - misses.width - 65;
		}
		
		if (orangeBox != null)
		{
			if (notesHitTxt != null)
			{
				notesHitTxt.x = orangeBox.x + 15;
				notesHitTxt.y = orangeBox.y - 3;
			}
			
			if (notesHit != null)
			{
				notesHit.x = orangeBox.x + 570 - notesHit.width - 15;
				notesHit.y = orangeBox.y - 3;
			}
		}
	}
}

// be so fr.
private class GradientShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		void main()
		{
            vec2 uv = openfl_TextureCoordv;

            vec3 gradTop = vec3(1.0, 0.1, 0.0);
            vec3 gradBottom = vec3(1.0, 1.0, 0.0);

            vec3 gradient = mix(gradTop,gradBottom,uv.y);

            vec4 tex = flixel_texture2D(bitmap,uv);

            tex.rgb *= gradient;

			gl_FragColor = tex;

		}
            
        ')
	public function new()
	{
		super();
	}
}
